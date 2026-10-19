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
    private let defaults = UserDefaults.standard

    private init() {}

    var access: CaptureAccess {
        if CGPreflightScreenCaptureAccess() { return .allowed }
        if defaults.bool(forKey: requestedKey) { return .denied }
        return .unchecked
    }

    @discardableResult
    func requestAccess() -> CaptureAccess {
        CGRequestScreenCaptureAccess()
        defaults.set(true, forKey: requestedKey)
        return access
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
    func captureImage(filter: SCContentFilter) async throws -> CGImage {
        if #available(macOS 14.0, *) {
            let config = SCStreamConfiguration()
            config.showsCursor = false
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } else {
            return try await captureImageViaStream(filter: filter)
        }
    }

    private func captureImageViaStream(filter: SCContentFilter) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            let receiver = SingleShotReceiver()
            receiver.completion = { result in
                switch result {
                case .success(let image): continuation.resume(returning: image)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
            Task { [weak receiver] in
                do {
                    let config = SCStreamConfiguration()
                    config.showsCursor = false
                    config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
                    let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                    guard let receiver else { throw CaptureError.cancelled }
                    try stream.addStreamOutput(receiver, type: .screen, sampleHandlerQueue: DispatchQueue(label: "localink.shot"))
                    try await stream.startCapture()
                    try await Task.sleep(nanoseconds: 200_000_000)
                    try await stream.stopCapture()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum CaptureError: Error {
    case cancelled
}

private final class SingleShotReceiver: NSObject, SCStreamOutput {
    var completion: ((Result<CGImage, Error>) -> Void)?
    private var delivered = false

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard !delivered, outputType == .screen else { return }
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: buffer)
        let context = CIContext(options: nil)
        if let cg = context.createCGImage(ci, from: ci.extent) {
            delivered = true
            completion?(.success(cg))
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

    func start(filter: SCContentFilter) async throws {
        let config = SCStreamConfiguration()
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
