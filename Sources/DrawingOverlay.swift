import AppKit
import Carbon

// MARK: - Text editor

final class TextAnnotationEditor: NSTextView {
    var onCommit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            onCancel?()
            return
        }
        if event.keyCode == UInt16(kVK_Return) && event.modifierFlags.contains(.command) {
            onCommit?(string)
            return
        }
        super.keyDown(with: event)
    }

    override func didChangeText() {
        super.didChangeText()
        let fixedWidth = max(frame.width, 120)
        let textHeight = attributedString().size().height + 12
        let newHeight = max(28, min(textHeight, 600))
        setFrameSize(NSSize(width: fixedWidth, height: newHeight))
    }
}

// MARK: - Drawing overlay

final class DrawingOverlay: NSView {
    var drawingEnabled = false
    var tool: DrawingTool = .pen
    var showHalo = false
    var showSpotlight = false
    var whiteboardActive = false
    var cursorPoint = CGPoint(x: -10000, y: -10000)

    weak var coordinator: OverlayCoordinator?

    private(set) var marks: [Annotation] = []
    private(set) var boardMarks: [Annotation] = []

    private var currentMark: Annotation?
    private var selectedID: UUID?
    private var moveOrigin: CGPoint?
    private var moveDelta = CGPoint.zero
    private var activeTextEditor: TextAnnotationEditor?
    private var rippleOrigin: CGPoint?
    private var rippleStart: TimeInterval = 0

    private var prefs: Preferences { .shared }

    var activeMarks: [Annotation] { whiteboardActive ? boardMarks : marks }

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        NSColor.clear.setFill()
        dirtyRect.fill()

        if whiteboardActive {
            prefs.whiteboardColor.nsColor.setFill()
            bounds.fill()
        }

        if bounds.contains(cursorPoint) && showSpotlight {
            drawSpotlight(in: ctx)
        }

        let all = whiteboardActive ? boardMarks : marks
        for mark in all {
            if mark.id == selectedID, let delta = currentMoveDelta {
                Renderer.draw(mark.translated(by: delta), in: ctx)
            } else {
                Renderer.draw(mark, in: ctx)
            }
        }
        if let currentMark { Renderer.draw(currentMark, in: ctx) }

        if let id = selectedID, let mark = all.first(where: { $0.id == id }) {
            drawSelectionBox(for: mark, in: ctx)
        }

        if bounds.contains(cursorPoint) && showHalo {
            drawHalo(in: ctx)
        }

        if let origin = rippleOrigin {
            drawRipple(at: origin, in: ctx)
        }
    }

    private var currentMoveDelta: CGPoint? {
        guard selectedID != nil, moveOrigin != nil else { return nil }
        return moveDelta
    }

    private func drawSpotlight(in ctx: CGContext) {
        let size = prefs.spotlightSize
        let dim = prefs.spotlightDimLevel
        let shade = NSBezierPath(rect: bounds)
        shade.appendOval(in: CGRect(x: cursorPoint.x - size, y: cursorPoint.y - size,
                                    width: size * 2, height: size * 2))
        shade.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(dim).setFill()
        shade.fill()
    }

    private func drawHalo(in ctx: CGContext) {
        let size = prefs.haloSize
        let color = prefs.haloColor.withAlpha(prefs.haloColor.alpha * prefs.haloOpacity).nsColor
        let ring = NSBezierPath(ovalIn: CGRect(x: cursorPoint.x - size,
                                               y: cursorPoint.y - size,
                                               width: size * 2, height: size * 2))
        ring.lineWidth = 4
        color.setStroke()
        ring.stroke()
        if !prefs.haloRingOnly {
            let center = NSBezierPath(ovalIn: CGRect(x: cursorPoint.x - 4, y: cursorPoint.y - 4,
                                                     width: 8, height: 8))
            color.setFill()
            center.fill()
        }
    }

    private func drawRipple(at origin: CGPoint, in ctx: CGContext) {
        let elapsed = ProcessInfo.processInfo.systemUptime - rippleStart
        let progress = elapsed / 0.45
        guard progress < 1 else {
            rippleOrigin = nil
            return
        }
        let maxRadius: CGFloat = 40
        let radius = maxRadius * (1 - (1 - progress) * (1 - progress))
        let alpha = (1 - progress) * 0.5
        let ring = NSBezierPath(ovalIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                               width: radius * 2, height: radius * 2))
        ring.lineWidth = 3
        prefs.haloColor.withAlpha(alpha).nsColor.setStroke()
        ring.stroke()
    }

    private func drawSelectionBox(for mark: Annotation, in ctx: CGContext) {
        let box = mark.boundingBox.insetBy(dx: -4, dy: -4)
        let path = NSBezierPath(roundedRect: box, xRadius: 4, yRadius: 4)
        path.lineWidth = 1.5
        let dash: [CGFloat] = [5, 3]
        path.setLineDash(dash, count: 2, phase: 0)
        NSColor.systemBlue.setStroke()
        path.stroke()
    }

    // MARK: Input

    override func mouseDown(with event: NSEvent) {
        guard drawingEnabled else { return }
        let point = convert(event.locationInWindow, from: nil)

        if activeTextEditor != nil {
            commitTextEditor()
            return
        }

        rippleOrigin = point
        rippleStart = ProcessInfo.processInfo.systemUptime

        if tool == .text {
            beginTextEditing(at: point)
            return
        }

        if tool == .select {
            beginSelection(at: point)
            return
        }

        let expiry = prefs.autoEraseDelay > 0 ? prefs.autoEraseDelay : nil
        let mark = Annotation(tool: tool,
                              points: [point],
                              color: prefs.inkColor,
                              thickness: prefs.inkWidth,
                              opacity: prefs.inkOpacity,
                              expiry: expiry)
        currentMark = mark
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard drawingEnabled else { return }
        let point = convert(event.locationInWindow, from: nil)

        if selectedID != nil, moveOrigin != nil {
            moveDelta = CGPoint(x: point.x - moveOrigin!.x, y: point.y - moveOrigin!.y)
            needsDisplay = true
            return
        }

        guard var mark = currentMark else { return }
        let constrained = applyConstraint(from: mark.points[0], to: point, event: event)
        switch tool {
        case .pen, .highlighter:
            mark.points.append(constrained)
        default:
            if mark.points.count == 1 { mark.points.append(constrained) }
            else { mark.points[1] = constrained }
        }
        currentMark = mark
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard drawingEnabled else { return }

        if selectedID != nil, moveOrigin != nil {
            finishSelectionMove()
            return
        }

        guard var mark = currentMark else { return }
        currentMark = nil
        let point = convert(event.locationInWindow, from: nil)
        if mark.points.count == 1 {
            let constrained = applyConstraint(from: mark.points[0], to: point, event: event)
            if tool == .pen || tool == .highlighter {
                mark.points.append(CGPoint(x: point.x + 0.01, y: point.y + 0.01))
            } else {
                mark.points.append(constrained)
            }
        }
        coordinator?.commitMark(mark, on: self)
        needsDisplay = true
    }

    private func applyConstraint(from start: CGPoint, to end: CGPoint, event: NSEvent) -> CGPoint {
        guard event.modifierFlags.contains(.shift) else { return end }
        let dx = end.x - start.x
        let dy = end.y - start.y
        switch tool {
        case .rectangle, .ellipse:
            let side = max(abs(dx), abs(dy))
            return CGPoint(x: start.x + (dx < 0 ? -side : side),
                           y: start.y + (dy < 0 ? -side : side))
        case .arrow:
            let angle = atan2(dy, dx)
            let snapped = (angle / (.pi / 4)).rounded() * (.pi / 4)
            let length = hypot(dx, dy)
            return CGPoint(x: start.x + length * cos(snapped),
                           y: start.y + length * sin(snapped))
        default:
            return end
        }
    }

    // MARK: Selection

    private func beginSelection(at point: CGPoint) {
        if let index = activeMarks.lastIndex(where: { $0.contains(point) }) {
            selectedID = activeMarks[index].id
        } else {
            selectedID = nil
        }
        moveOrigin = point
        moveDelta = .zero
        needsDisplay = true
    }

    private func finishSelectionMove() {
        if let id = selectedID, moveOrigin != nil,
           abs(moveDelta.x) > 0.5 || abs(moveDelta.y) > 0.5 {
            coordinator?.moveMark(id: id, by: moveDelta, on: self)
        }
        moveOrigin = nil
        moveDelta = .zero
        needsDisplay = true
    }

    func deleteSelected() {
        guard let id = selectedID else { return }
        selectedID = nil
        coordinator?.deleteMark(id: id, on: self)
    }

    func deselect() {
        selectedID = nil
        moveOrigin = nil
        moveDelta = .zero
        needsDisplay = true
    }

    var hasSelection: Bool { selectedID != nil }

    var selectedMark: Annotation? {
        guard let id = selectedID else { return nil }
        return activeMarks.first { $0.id == id }
    }

    var selectedMarkID: UUID? { selectedID }

    // MARK: Text

    private func beginTextEditing(at point: CGPoint) {
        let fontSize = max(18, prefs.inkWidth * 6)
        let editor = TextAnnotationEditor(frame: CGRect(x: point.x, y: point.y - fontSize,
                                                        width: 220, height: fontSize + 10))
        editor.isRichText = false
        editor.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        editor.textColor = prefs.inkColor.nsColor
        editor.backgroundColor = .clear
        editor.drawsBackground = false
        editor.insertionPointColor = prefs.inkColor.nsColor
        editor.isVerticallyResizable = true
        editor.textContainerInset = NSSize(width: 2, height: 2)
        editor.autoresizingMask = [.width]
        editor.onCommit = { [weak self] text in
            guard let self else { return }
            self.activeTextEditor = nil
            editor.removeFromSuperview()
            if !text.isEmpty {
                let mark = Annotation(tool: .text,
                                      points: [point],
                                      color: self.prefs.inkColor,
                                      thickness: self.prefs.inkWidth,
                                      opacity: self.prefs.inkOpacity,
                                      text: text,
                                      fontSize: fontSize)
                self.coordinator?.commitMark(mark, on: self)
            }
        }
        editor.onCancel = { [weak self] in
            guard let self else { return }
            self.activeTextEditor = nil
            editor.removeFromSuperview()
        }
        addSubview(editor)
        activeTextEditor = editor
        window?.makeFirstResponder(editor)
        window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        needsDisplay = true
    }

    private func commitTextEditor() {
        if let editor = activeTextEditor {
            let text = editor.string
            editor.onCommit?(text)
        }
    }

    // MARK: Model access (called by coordinator + undo stack)

    func appendMark(_ mark: Annotation) {
        if whiteboardActive { boardMarks.append(mark) } else { marks.append(mark) }
        needsDisplay = true
    }

    func removeMark(id: UUID) {
        marks.removeAll { $0.id == id }
        boardMarks.removeAll { $0.id == id }
        if selectedID == id { selectedID = nil }
        needsDisplay = true
    }

    func moveMark(id: UUID, delta: CGPoint) {
        for i in marks.indices where marks[i].id == id { marks[i] = marks[i].translated(by: delta) }
        for i in boardMarks.indices where boardMarks[i].id == id { boardMarks[i] = boardMarks[i].translated(by: delta) }
        needsDisplay = true
    }

    func clearActiveCanvas() {
        if whiteboardActive { boardMarks.removeAll() } else { marks.removeAll() }
        selectedID = nil
        needsDisplay = true
    }

    func clearAll() {
        marks.removeAll()
        boardMarks.removeAll()
        selectedID = nil
        needsDisplay = true
    }

    func setMarks(_ newMarks: [Annotation], board newBoard: [Annotation]) {
        marks = newMarks
        boardMarks = newBoard
        selectedID = nil
        needsDisplay = true
    }

    func insertMarks(_ newMarks: [Annotation]) {
        if whiteboardActive { boardMarks.append(contentsOf: newMarks) } else { marks.append(contentsOf: newMarks) }
        needsDisplay = true
    }

    func removeMarks(ids: [UUID]) {
        let set = Set(ids)
        marks.removeAll { set.contains($0.id) }
        boardMarks.removeAll { set.contains($0.id) }
        needsDisplay = true
    }

    func expireMarks() {
        let now = Date()
        marks.removeAll { mark in
            if let expiry = mark.expiry {
                return now.timeIntervalSince(mark.createdAt) >= expiry
            }
            return false
        }
        boardMarks.removeAll { mark in
            if let expiry = mark.expiry {
                return now.timeIntervalSince(mark.createdAt) >= expiry
            }
            return false
        }
        needsDisplay = true
    }
}
