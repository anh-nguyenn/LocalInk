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

// MARK: - Overlay panel

// Borderless panels cannot become key by default, which prevents text editing
// and local key handling. The overlay needs key status while drawing, so opt in
// explicitly.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
    private var lastCursorLocation: NSPoint?

    private let sessionKey = "LocalInk.savedSession"

    private struct CanvasSnapshot: Codable {
        var marks: [Annotation]
        var boardMarks: [Annotation]
    }

    var onChange: (() -> Void)?
    var reloadHotkeys: (() -> Void)?

    // MARK: Display setup

    func makeWindows() {
        var snapshots: [CGDirectDisplayID: CanvasSnapshot] = [:]
        for overlay in overlays {
            snapshots[overlay.screenDisplayID] = CanvasSnapshot(marks: overlay.marks,
                                                                boardMarks: overlay.boardMarks)
        }

        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        overlays.removeAll()
        // Undo closures capture the overlays that just went away, so the stack
        // cannot survive a rebuild. Annotations themselves are restored below.
        undoStack.removeAll()

        let fallback = snapshots.count == 1 ? snapshots.values.first : nil
        for screen in NSScreen.screens {
            let panel = OverlayPanel(contentRect: screen.frame,
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
            overlay.screenDisplayID = screen.displayID
            if let snapshot = snapshots[screen.displayID] ?? fallback {
                overlay.setMarks(snapshot.marks, board: snapshot.boardMarks)
            }
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
        overlays.first { $0.screenDisplayID == displayID }
    }

    // MARK: Session persistence

    func saveSession() {
        let defaults = UserDefaults.standard
        guard Preferences.shared.sessionRetention == "untilClear" else {
            defaults.removeObject(forKey: sessionKey)
            return
        }
        var snapshots: [String: CanvasSnapshot] = [:]
        for overlay in overlays {
            snapshots[String(overlay.screenDisplayID)] = CanvasSnapshot(marks: overlay.marks,
                                                                        boardMarks: overlay.boardMarks)
        }
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: sessionKey)
        }
    }

    func restoreSession() {
        let defaults = UserDefaults.standard
        guard Preferences.shared.sessionRetention == "untilClear" else {
            defaults.removeObject(forKey: sessionKey)
            return
        }
        guard let data = defaults.data(forKey: sessionKey),
              let snapshots = try? JSONDecoder().decode([String: CanvasSnapshot].self, from: data) else {
            return
        }
        for overlay in overlays {
            guard let snapshot = snapshots[String(overlay.screenDisplayID)] else { continue }
            overlay.setMarks(snapshot.marks, board: snapshot.boardMarks)
        }
        notifyChange()
    }

    private func notifyChange() {
        saveSession()
        onChange?()
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
        guard mouseTimer == nil else { return }
        mouseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func refreshTimer() {
        let needsTimer = state.haloEnabled || state.spotlightEnabled ||
            state.annotationMode != .off || Preferences.shared.autoEraseDelay > 0
        if needsTimer {
            startTimer()
        } else {
            stopTimer()
        }
    }

    func stopTimer() {
        mouseTimer?.invalidate()
        mouseTimer = nil
    }

    private func tick() {
        // Once a Command-click reaches another app, LocalInk stops receiving
        // local key events. Poll the session modifier state so releasing
        // Command always re-enables drawing.
        if state.drawingEnabled {
            let commandHeld = CGEventSource.flagsState(.combinedSessionState).contains(.maskCommand)
            setPassThroughHeld(commandHeld)
        }

        let needsCursor = state.haloEnabled || state.spotlightEnabled
        if needsCursor {
            let location = NSEvent.mouseLocation
            let moved = lastCursorLocation != location
            lastCursorLocation = location
            for (window, overlay) in zip(windows, overlays) {
                overlay.cursorPoint = overlay.convert(window.convertPoint(fromScreen: location), from: nil)
                if moved || overlay.needsAnimationFrame {
                    overlay.needsDisplay = true
                }
            }
        } else {
            lastCursorLocation = nil
            for overlay in overlays where overlay.needsAnimationFrame {
                overlay.needsDisplay = true
            }
        }

        if Preferences.shared.autoEraseDelay > 0 {
            for overlay in overlays {
                let expired = overlay.expireMarks()
                guard !expired.marks.isEmpty || !expired.boardMarks.isEmpty else { continue }
                let marks = expired.marks
                let boardMarks = expired.boardMarks
                let ids = (marks + boardMarks).map { $0.id }
                undoStack.register(EditAction(
                    undo: { [weak overlay] in
                        // Restart the auto-erase clock when a mark is restored.
                        let now = Date()
                        func reviving(_ mark: Annotation) -> Annotation {
                            var copy = mark
                            copy.createdAt = now
                            return copy
                        }
                        overlay?.insertMarks(marks.map(reviving), toBoard: false)
                        overlay?.insertMarks(boardMarks.map(reviving), toBoard: true)
                    },
                    redo: { [weak overlay] in overlay?.removeMarks(ids: ids) }
                ))
                notifyChange()
            }
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
            overlay.whiteboardActive = state.whiteboardEnabled && state.annotationMode != .off
            if !state.drawingEnabled {
                overlay.cancelInProgressMark()
            }
            overlay.needsDisplay = true
        }
        refreshTimer()
        onChange?()
    }

    func setPassThroughHeld(_ held: Bool) {
        guard state.passThroughHeld != held else { return }
        state.passThroughHeld = held
        applyState()
    }

    // MARK: Model mutations (each becomes one undoable command)

    func commitMark(_ mark: Annotation, on overlay: DrawingOverlay) {
        let toBoard = overlay.whiteboardActive
        overlay.appendMark(mark, toBoard: toBoard)
        let id = mark.id
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.removeMark(id: id) },
            redo: { [weak overlay] in overlay?.appendMark(mark, toBoard: toBoard) }
        ))
        notifyChange()
    }

    func deleteMark(id: UUID, on overlay: DrawingOverlay) {
        guard let mark = (overlay.activeMarks.first { $0.id == id }) else { return }
        let toBoard = overlay.whiteboardActive
        overlay.removeMark(id: id)
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.appendMark(mark, toBoard: toBoard) },
            redo: { [weak overlay] in overlay?.removeMark(id: id) }
        ))
        notifyChange()
    }

    func moveMark(id: UUID, by delta: CGPoint, on overlay: DrawingOverlay) {
        overlay.moveMark(id: id, delta: delta)
        let inverse = CGPoint(x: -delta.x, y: -delta.y)
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.moveMark(id: id, delta: inverse) },
            redo: { [weak overlay] in overlay?.moveMark(id: id, delta: delta) }
        ))
        notifyChange()
    }

    func clearActiveCanvas(on overlay: DrawingOverlay) {
        let snapshot = overlay.activeMarks
        let toBoard = overlay.whiteboardActive
        overlay.clearActiveCanvas()
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.insertMarks(snapshot, toBoard: toBoard) },
            redo: { [weak overlay] in overlay?.clearActiveCanvas() }
        ))
        notifyChange()
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
        notifyChange()
    }

    func insertMarks(_ marks: [Annotation], on overlay: DrawingOverlay) {
        let toBoard = overlay.whiteboardActive
        overlay.insertMarks(marks, toBoard: toBoard)
        let ids = marks.map { $0.id }
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.removeMarks(ids: ids) },
            redo: { [weak overlay] in overlay?.insertMarks(marks, toBoard: toBoard) }
        ))
        notifyChange()
    }

    // Marks have already been removed by the eraser; register a single undo
    // entry for the whole gesture.
    func registerErase(_ removed: [Annotation], on overlay: DrawingOverlay) {
        guard !removed.isEmpty else { return }
        let toBoard = overlay.whiteboardActive
        let ids = removed.map { $0.id }
        undoStack.register(EditAction(
            undo: { [weak overlay] in overlay?.insertMarks(removed, toBoard: toBoard) },
            redo: { [weak overlay] in overlay?.removeMarks(ids: ids) }
        ))
        notifyChange()
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

    func undo() { undoStack.undo(); notifyChange() }
    func redo() { redoStackAction() }

    private func redoStackAction() { undoStack.redo(); notifyChange() }

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
