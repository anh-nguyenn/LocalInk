import AppKit

// MARK: - Undo stack

struct EditAction {
    let undo: () -> Void
    let redo: () -> Void
}

final class UndoStack {
    private var undoStack: [EditAction] = []
    private var redoStack: [EditAction] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func register(_ action: EditAction) {
        undoStack.append(action)
        redoStack.removeAll()
    }

    func undo() {
        guard let action = undoStack.popLast() else { return }
        action.undo()
        redoStack.append(action)
    }

    func redo() {
        guard let action = redoStack.popLast() else { return }
        action.redo()
        undoStack.append(action)
    }

    func removeAll() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - Overlay coordinator

// Owns one transparent presentation surface per display, keeps the annotation
// model in sync with those surfaces, and drives the undo/redo stack. All UI
// state is mutated on the main actor (the main thread in this AppKit app).
final class OverlayCoordinator {
    let state = StateController()
    let undoStack = UndoStack()
    var annotationClipboard: [Annotation] = []

    private(set) var windows: [NSPanel] = []
    private(set) var overlays: [DrawingOverlay] = []
    private var mouseTimer: Timer?

    var onChange: (() -> Void)?
    var reloadHotkeys: (() -> Void)?

    // MARK: Display setup

    func makeWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        overlays.removeAll()
        undoStack.removeAll()
        annotationClipboard.removeAll()
        state.counterNext = 1

        for screen in NSScreen.screens {
            let panel = NSPanel(contentRect: screen.frame,
                                styleMask: [.borderless],
                                backing: .buffered, defer: false)
            panel.level = .screenSaver
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.isFloatingPanel = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isReleasedWhenClosed = false
            panel.ignoresMouseEvents = true

            let overlay = DrawingOverlay(frame: NSRect(origin: .zero, size: screen.frame.size))
            overlay.autoresizingMask = [.width, .height]
            overlay.coordinator = self
            panel.contentView = overlay
            panel.orderFrontRegardless()
            windows.append(panel)
            overlays.append(overlay)
        }
        applyState()
    }

    @objc func displaysChanged() {
        makeWindows()
    }

    func overlay(for displayID: CGDirectDisplayID) -> DrawingOverlay? {
        for (index, window) in windows.enumerated() where window.screen?.displayID == displayID {
            return overlays[index]
        }
        return nil
    }

    func takeNextCounter() -> Int {
        let value = state.counterNext
        state.counterNext += 1
        return value
    }

    func focusOverlayUnderMouse() {
        let mouse = NSEvent.mouseLocation
        for (index, window) in windows.enumerated() where window.frame.contains(mouse) {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(overlays[index])
            return
        }
        windows.first?.makeKeyAndOrderFront(nil)
    }

    func resetCounter() {
        state.counterNext = 1
    }

    func startTimer() {
        stopTimer()
        mouseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTimer() {
        mouseTimer?.invalidate()
        mouseTimer = nil
    }

    private func tick() {
        let needsCursor = state.haloEnabled || state.spotlightEnabled
        if needsCursor {
            let location = NSEvent.mouseLocation
            for (window, overlay) in zip(windows, overlays) {
                overlay.cursorPoint = overlay.convert(window.convertPoint(fromScreen: location), from: nil)
                overlay.needsDisplay = true
            }
        }
        if Preferences.shared.autoEraseDelay > 0 {
            overlays.forEach { $0.expireMarks() }
        }
    }

    // MARK: State application

    func applyState() {
        let capture = state.shouldCaptureMouse
        for (window, overlay) in zip(windows, overlays) {
            window.ignoresMouseEvents = !capture
            overlay.drawingEnabled = state.drawingEnabled
            overlay.showHalo = state.haloEnabled
            overlay.showSpotlight = state.spotlightEnabled
            overlay.tool = state.activeTool
            overlay.whiteboardActive = state.whiteboardEnabled
            if !state.drawingEnabled {
                overlay.cancelInProgressMark()
            }
            overlay.needsDisplay = true
        }
        onChange?()
    }

    func setPassThroughHeld(_ held: Bool) {
        guard state.passThroughHeld != held else { return }
        state.passThroughHeld = held
        applyState()
    }

    // MARK: Model mutations (each becomes one undoable command)

    func commitMark(_ mark: Annotation, on overlay: DrawingOverlay) {
        overlay.appendMark(mark)
        let id = mark.id
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.removeMark(id: id) },
            redo: { [weak overlay] in overlay?.appendMark(mark) }
        ))
        onChange?()
    }

    func deleteMark(id: UUID, on overlay: DrawingOverlay) {
        guard let mark = (overlay.activeMarks.first { $0.id == id }) else { return }
        overlay.removeMark(id: id)
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.appendMark(mark) },
            redo: { [weak overlay] in overlay?.removeMark(id: id) }
        ))
        onChange?()
    }

    func moveMark(id: UUID, by delta: CGPoint, on overlay: DrawingOverlay) {
        overlay.moveMark(id: id, delta: delta)
        let inverse = CGPoint(x: -delta.x, y: -delta.y)
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.moveMark(id: id, delta: inverse) },
            redo: { [weak overlay] in overlay?.moveMark(id: id, delta: delta) }
        ))
        onChange?()
    }

    func clearActiveCanvas(on overlay: DrawingOverlay) {
        let snapshot = overlay.activeMarks
        overlay.clearActiveCanvas()
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.insertMarks(snapshot) },
            redo: { [weak overlay] in overlay?.clearActiveCanvas() }
        ))
        onChange?()
    }

    func clearAllDisplays() {
        state.counterNext = 1
        var snapshots: [(DrawingOverlay, [Annotation], [Annotation])] = []
        for overlay in overlays {
            snapshots.append((overlay, overlay.marks, overlay.boardMarks))
            overlay.clearAll()
        }
        undoStack.register(EditAction(
            undo: { [weak self] in
                for (overlay, marks, board) in snapshots {
                    overlay.setMarks(marks, board: board)
                }
                _ = self
            },
            redo: { [weak self] in
                self?.overlays.forEach { $0.clearAll() }
            }
        ))
        onChange?()
    }

    func insertMarks(_ marks: [Annotation], on overlay: DrawingOverlay) {
        overlay.insertMarks(marks)
        let ids = marks.map { $0.id }
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.removeMarks(ids: ids) },
            redo: { [weak overlay] in overlay?.insertMarks(marks) }
        ))
        onChange?()
    }

    // Marks have already been removed by the eraser; register a single undo
    // entry for the whole gesture.
    func registerErase(_ removed: [Annotation], on overlay: DrawingOverlay) {
        guard !removed.isEmpty else { return }
        let ids = removed.map { $0.id }
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.insertMarks(removed) },
            redo: { [weak overlay] in overlay?.removeMarks(ids: ids) }
        ))
        onChange?()
    }

    func isEditingText() -> Bool {
        overlays.contains { $0.isEditingText }
    }

    func cancelTextEditing() {
        overlays.forEach { $0.cancelTextEditing() }
    }

    func deleteLastMark(on overlay: DrawingOverlay) {
        guard let last = overlay.activeMarks.last else { return }
        deleteMark(id: last.id, on: overlay)
    }

    func undo() { undoStack.undo(); onChange?() }
    func redo() { redoStackAction() }

    private func redoStackAction() { undoStack.redo(); onChange?() }

    // MARK: Clipboard (copy / paste)

    func copySelection(from overlay: DrawingOverlay) {
        guard let mark = overlay.selectedMark else { return }
        annotationClipboard = [mark]
        onChange?()
    }

    func paste(on overlay: DrawingOverlay) {
        guard !annotationClipboard.isEmpty else { return }
        let offset = CGPoint(x: 24, y: -24)
        let copies = annotationClipboard.map { original -> Annotation in
            var copy = original
            copy = Annotation(id: UUID(),
                              tool: original.tool,
                              points: original.points.map { CGPoint(x: $0.x + offset.x, y: $0.y + offset.y) },
                              color: original.color,
                              thickness: original.thickness,
                              opacity: original.opacity,
                              text: original.text,
                              fontSize: original.fontSize,
                              createdAt: Date(),
                              expiry: nil)
            return copy
        }
        insertMarks(copies, on: overlay)
    }
}
