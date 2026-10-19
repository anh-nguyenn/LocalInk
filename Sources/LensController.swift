import AppKit

// MARK: - Lens view

final class LensView: NSView {
    var latestImage: CGImage?
    var zoomFactor: CGFloat = 2.5
    var fullscreen = false
    var screen: NSScreen?

    // Keep AppKit's default (unflipped) coordinates. Drawing a CGImage into a
    // flipped view vertically mirrors it.
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let latestImage, let ctx = NSGraphicsContext.current?.cgContext, let screen else {
            NSColor.clear.setFill()
            dirtyRect.fill()
            return
        }

        let mouse = NSEvent.mouseLocation
        let localX = mouse.x - screen.frame.minX
        let localY = mouse.y - screen.frame.minY

        let effectiveScale = CGFloat(latestImage.width) / screen.frame.width
        let centerPixelX = localX * effectiveScale
        let centerPixelY = (screen.frame.height - localY) * effectiveScale

        let srcPixel = (bounds.width / zoomFactor) * effectiveScale
        let srcRect = CGRect(x: centerPixelX - srcPixel / 2,
                             y: centerPixelY - srcPixel / 2,
                             width: srcPixel, height: srcPixel)

        guard let sub = latestImage.cropping(to: srcRect.integral) ?? latestImage.cropping(to: srcRect) else {
            return
        }

        ctx.saveGState()
        if fullscreen {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)
        } else {
            let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
            circle.addClip()
        }
        ctx.interpolationQuality = .high
        ctx.draw(sub, in: bounds)
        ctx.restoreGState()

        if !fullscreen {
            let ring = NSBezierPath(ovalIn: bounds.insetBy(dx: 1.5, dy: 1.5))
            ring.lineWidth = 3
            NSColor.white.withAlphaComponent(0.9).setStroke()
            ring.stroke()
            let shadow = NSBezierPath(ovalIn: bounds.insetBy(dx: 0, dy: 0))
            shadow.lineWidth = 1
            NSColor.black.withAlphaComponent(0.4).setStroke()
            shadow.stroke()
        }
    }
}

// MARK: - Lens controller

// Magnifier and fullscreen zoom. A single continuous capture stream feeds a
// click-through panel that shows an enlarged region around the pointer.
final class LensController {
    var localWindowIDs: (() -> Set<CGWindowID>)?

    private var panel: NSPanel?
    private var lensView: LensView?
    private var capture: ContinuousCapture?
    private var timer: Timer?
    private var generation = 0
    private(set) var mode: ZoomMode = .off

    func start(_ newMode: ZoomMode) {
        guard CaptureService.shared.access == .allowed else { return }
        stop()

        guard let screen = screenUnderMouse() else { return }
        mode = newMode
        generation += 1
        let token = generation

        let size = newMode == .fullscreen ? screen.frame.size : NSSize(width: Preferences.shared.lensSize,
                                                                       height: Preferences.shared.lensSize)
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.level = .screenSaver + 2
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = LensView(frame: NSRect(origin: .zero, size: size))
        view.zoomFactor = Preferences.shared.zoomFactor
        view.fullscreen = newMode == .fullscreen
        view.screen = screen
        panel.contentView = view

        self.panel = panel
        self.lensView = view

        if newMode == .fullscreen {
            panel.setFrameOrigin(screen.frame.origin)
        }
        panel.orderFrontRegardless()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.positionLens()
            self?.lensView?.needsDisplay = true
        }

        Task { [weak self] in
            await self?.beginCapture(token: token)
        }
    }

    func stop() {
        generation += 1
        capture?.stop()
        capture = nil
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
        lensView = nil
        mode = .off
    }

    private func screenUnderMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func positionLens() {
        guard mode == .lens, let panel, let screen = lensView?.screen else { return }
        let mouse = NSEvent.mouseLocation
        let offset: CGFloat = 24
        var origin = NSPoint(x: mouse.x + offset, y: mouse.y - panel.frame.height - offset)
        if origin.x + panel.frame.width > screen.frame.maxX {
            origin.x = mouse.x - panel.frame.width - offset
        }
        if origin.y < screen.frame.minY {
            origin.y = mouse.y + offset
        }
        panel.setFrameOrigin(origin)
    }

    private func beginCapture(token: Int) async {
        guard let screen = lensView?.screen else { return }
        let pixelSize = CGSize(width: screen.frame.width * screen.backingScaleFactor,
                               height: screen.frame.height * screen.backingScaleFactor)
        do {
            let content = try await CaptureService.shared.shareableContent()
            guard token == generation,
                  let display = CaptureService.shared.display(screen.displayID, in: content) else { return }
            var excluded = localWindowIDs?() ?? []
            if let panel { excluded.insert(CGWindowID(panel.windowNumber)) }
            let filter = CaptureService.shared.filter(display: display, excluding: excluded, in: content)
            let configuration = CaptureService.shared.configuration(pixelSize: pixelSize)
            let capture = ContinuousCapture()
            capture.onImage = { [weak self] image in
                self?.lensView?.latestImage = image
                self?.lensView?.needsDisplay = true
            }
            guard token == generation else { return }
            self.capture = capture
            try await capture.start(filter: filter, configuration: configuration)
            if token != generation {
                capture.stop()
                if self.capture === capture { self.capture = nil }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self, token == self.generation else { return }
                self.stop()
            }
        }
    }
}
