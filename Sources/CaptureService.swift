import AppKit
import ScreenCaptureKit
import CoreImage
import CoreMedia

// MARK: - Capture permission

enum CaptureAccess {
    case unchecked
    case allowed
    case denied
}

// MARK: - Capture service

// Wraps ScreenCaptureKit for permission state, single-shot display capture, and
// a continuous stream used by the magnifier. Drawing, halo, and spotlight do
// not depend on this service.
final class CaptureService {
    static let shared = CaptureService()

    private let requestedKey = "LocalInk.captureRequested"
    private let requestedAtKey = "LocalInk.captureRequestedAt"
    private let defaults = UserDefaults.standard

    private init() {}

    var access: CaptureAccess {
        if CGPreflightScreenCaptureAccess() { return .allowed }
        // The system prompt is asynchronous. Treat the first few seconds after
        // asking as "pending" rather than immediately reporting a denial.
        if let requestedAt = defaults.object(forKey: requestedAtKey) as? Date {
            return Date().timeIntervalSince(requestedAt) > 3 ? .denied : .unchecked
        }
        if defaults.bool(forKey: requestedKey) { return .denied }
        return .unchecked
    }

    @discardableResult
    func requestAccess() -> CaptureAccess {
        defaults.set(true, forKey: requestedKey)
        defaults.set(Date(), forKey: requestedAtKey)
        CGRequestScreenCaptureAccess()
        return access
    }

    // MARK: Configuration

    // ScreenCaptureKit defaults to 1920x1080 on macOS. Always set an explicit
    // pixel size so exports and the lens match the display exactly.
    func configuration(pixelSize: CGSize, showsCursor: Bool = false) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.width = max(1, Int(pixelSize.width.rounded()))
        config.height = max(1, Int(pixelSize.height.rounded()))
        config.showsCursor = showsCursor
        if #available(macOS 14.0, *) {
            config.captureResolution = .best
        }
        return config
    }

    func shareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func display(_ id: CGDirectDisplayID, in content: SCShareableContent) -> SCDisplay? {
        content.displays.first { $0.displayID == id }
    }

    func filter(display: SCDisplay, excluding ids: Set<CGWindowID>, in content: SCShareableContent) -> SCContentFilter {
        let excluded = content.windows.filter { ids.contains($0.windowID) }
        return SCContentFilter(display: display, excludingWindows: excluded)
    }

    // Single-shot capture used by export.
    func captureImage(filter: SCContentFilter, pixelSize: CGSize) async throws -> CGImage {
        let config = configuration(pixelSize: pixelSize, showsCursor: false)
        if #available(macOS 14.0, *) {
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } else {
            return try await captureImageViaStream(filter: filter, configuration: config)
        }
    }

    private func captureImageViaStream(filter: SCContentFilter,
                                       configuration: SCStreamConfiguration) async throws -> CGImage {
        let receiver = SingleShotReceiver()
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addStreamOutput(receiver, type: .screen,
                                   sampleHandlerQueue: DispatchQueue(label: "localink.shot"))
        try await stream.startCapture()
        do {
            let image = try await receiver.wait(timeout: 2)
            try? await stream.stopCapture()
            return image
        } catch {
            try? await stream.stopCapture()
            throw error
        }
    }
}

enum CaptureError: LocalizedError {
    case cancelled
    case timedOut

    var errorDescription: String? {
        switch self {
        case .cancelled: return "The capture was cancelled."
        case .timedOut: return "The screen capture timed out. Try again."
        }
    }
}

private final class SingleShotReceiver: NSObject, SCStreamOutput {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<CGImage, Error>?
    private var result: Result<CGImage, Error>?
    private var settled = false
    private var timeoutWorkItem: DispatchWorkItem?

    func wait(timeout: TimeInterval) async throws -> CGImage {
        defer { timeoutWorkItem?.cancel() }
        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if let result {
                lock.unlock()
                continuation.resume(with: result)
                return
            }
            self.continuation = continuation
            lock.unlock()

            let item = DispatchWorkItem { [weak self] in
                self?.finish(.failure(CaptureError.timedOut))
            }
            timeoutWorkItem = item
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: item)
        }
    }

    func finish(_ newResult: Result<CGImage, Error>) {
        lock.lock()
        guard !settled else {
            lock.unlock()
            return
        }
        settled = true
        let pending = continuation
        self.continuation = nil
        if pending == nil { result = newResult }
        lock.unlock()
        timeoutWorkItem?.cancel()
        pending?.resume(with: newResult)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: buffer)
        let context = CIContext(options: nil)
        if let cg = context.createCGImage(ci, from: ci.extent) {
            finish(.success(cg))
        }
    }
}

// MARK: - Continuous capture (magnifier)

final class ContinuousCapture: NSObject, SCStreamOutput {
    var onImage: ((CGImage) -> Void)?
    var onError: ((Error) -> Void)?

    private var stream: SCStream?
    private let queue = DispatchQueue(label: "localink.stream")
    private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])

    func start(filter: SCContentFilter, configuration: SCStreamConfiguration) async throws {
        let config = configuration
        config.showsCursor = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 3
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() {
        let stream = self.stream
        self.stream = nil
        guard let stream else { return }
        Task {
            try? await stream.stopCapture()
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: buffer)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return }
        let image = cg
        DispatchQueue.main.async { [weak self] in
            self?.onImage?(image)
        }
    }
}
