import AppKit
import Carbon

// MARK: - App coordinator

final class AppCoordinator: NSObject, NSApplicationDelegate {
    let coordinator = OverlayCoordinator()
    let hotkeys = HotkeyManager()
    let toolbar = ToolbarController()
    let settings = SettingsController()
    let lens = LensController()

    private var statusItem: NSStatusItem!
    private var mouseTimer: Timer?

    private var drawingMenuItem: NSMenuItem!
    private var haloMenuItem: NSMenuItem!
    private var spotlightMenuItem: NSMenuItem!
    private var whiteboardMenuItem: NSMenuItem!
    private var undoMenuItem: NSMenuItem!
    private var redoMenuItem: NSMenuItem!
    private var toolbarMenuItem: NSMenuItem!
    private var magnifierMenuItem: NSMenuItem!
    private var zoomMenuItem: NSMenuItem!
    private var conflictMenuItem: NSMenuItem!
    private var toolMenuItems: [DrawingTool: NSMenuItem] = [:]
    private var colorMenuItems: [InkColor: NSMenuItem] = [:]
    private var passThroughMonitor: Any?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(Preferences.shared.showDockIcon ? .regular : .accessory)

        toolbar.coordinator = coordinator
        settings.coordinator = coordinator
        lens.localWindowIDs = { [weak self] in self?.localWindowIDs() ?? [] }
        coordinator.onChange = { [weak self] in self?.refreshUI() }
        coordinator.reloadHotkeys = { [weak self] in self?.hotkeys.reload() }

        hotkeys.onAction = { [weak self] action in self?.handleShortcut(action) }
        hotkeys.onConflict = { [weak self] action in self?.refreshUI() }

        toolbar.onTool = { [weak self] tool in self?.setTool(tool) }
        toolbar.onColor = { [weak self] color in self?.setColor(color) }
        toolbar.onWidth = { [weak self] width in self?.setWidth(width) }
        toolbar.onUndo = { [weak self] in self?.undo() }
        toolbar.onRedo = { [weak self] in self?.redo() }
        toolbar.onClear = { [weak self] in self?.clearAll() }
        toolbar.onToggleHalo = { [weak self] in self?.toggleHalo() }
        toolbar.onToggleSpotlight = { [weak self] in self?.toggleSpotlight() }
        toolbar.onToggleWhiteboard = { [weak self] in self?.toggleWhiteboard() }
        toolbar.onPassThrough = { [weak self] in self?.togglePassThrough() }
        toolbar.onHide = { [weak self] in self?.hideToolbar() }

        settings.onChange = { [weak self] in
            self?.coordinator.applyState()
            self?.refreshUI()
        }

        coordinator.state.activeTool = Preferences.shared.inkTool

        setupMenu()
        coordinator.makeWindows()
        hotkeys.install()
        coordinator.startTimer()
        installPassThroughMonitor()

        NotificationCenter.default.addObserver(self,
            selector: #selector(displaysChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil)

        showFirstRunHelpIfNeeded()
        refreshUI()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stopTimer()
        hotkeys.uninstall()
        lens.stop()
        if let monitor = passThroughMonitor { NSEvent.removeMonitor(monitor) }
    }

    @objc private func displaysChanged() { coordinator.makeWindows() }

    @objc private func didWake() {
        lens.stop()
        coordinator.applyState()
    }

    // MARK: UI refresh

    private func refreshUI() {
        let state = coordinator.state
        drawingMenuItem.state = state.drawingEnabled ? .on : .off
        haloMenuItem.state = state.haloEnabled ? .on : .off
        spotlightMenuItem.state = state.spotlightEnabled ? .on : .off
        whiteboardMenuItem.state = state.whiteboardEnabled ? .on : .off
        magnifierMenuItem.state = lens.mode == .lens ? .on : .off
        zoomMenuItem.state = lens.mode == .fullscreen ? .on : .off
        undoMenuItem.isEnabled = coordinator.undoStack.canUndo
        redoMenuItem.isEnabled = coordinator.undoStack.canRedo

        for (tool, item) in toolMenuItems {
            item.state = state.activeTool == tool ? .on : .off
        }
        let currentColor = Preferences.shared.inkColor
        for (color, item) in colorMenuItems {
            item.state = color == currentColor ? .on : .off
        }

        statusItem.button?.image = NSImage(
            systemSymbolName: state.drawingEnabled ? "pencil.circle.fill" : "pencil.tip.crop.circle",
            accessibilityDescription: "LocalInk")

        if hotkeys.hasConflicts {
            let names = hotkeys.conflictingActions.map { $0.displayName }.joined(separator: ", ")
            conflictMenuItem.isHidden = false
            conflictMenuItem.title = "⚠ Some shortcuts are in use by another app (\(names))"
        } else {
            conflictMenuItem.isHidden = true
        }

        updateShortcutTitles()
        toolbar.refresh()
    }

    private func updateShortcutTitles() {
        let shortcuts = Preferences.shared.shortcuts
        func title(_ action: ShortcutAction, _ name: String) -> String {
            guard let s = shortcuts[action], s.isEnabled else { return name }
            return "\(name)   \(s.displayString)"
        }
        drawingMenuItem.title = title(.toggleDrawing, "Toggle Drawing")
        haloMenuItem.title = title(.toggleHalo, "Toggle Cursor Halo")
        spotlightMenuItem.title = title(.toggleSpotlight, "Toggle Spotlight")
        undoMenuItem.title = title(.undo, "Undo")
        redoMenuItem.title = title(.redo, "Redo")
        if let clearItem = clearMenuItem {
            clearItem.title = title(.clear, "Clear All Screens")
        }
    }

    private var clearMenuItem: NSMenuItem?

    // MARK: Menu

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "LocalInk")
            button.toolTip = "LocalInk — offline screen annotation"
        }

        let menu = NSMenu(title: "LocalInk")
        menu.addItem(NSMenuItem(title: "LocalInk — Local Screen Overlay", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())

        drawingMenuItem = addItem("Toggle Drawing", #selector(toggleDrawing), menu)
        haloMenuItem = addItem("Toggle Cursor Halo", #selector(toggleHalo), menu)
        spotlightMenuItem = addItem("Toggle Spotlight", #selector(toggleSpotlight), menu)
        whiteboardMenuItem = addItem("Toggle Whiteboard", #selector(toggleWhiteboard), menu)
        conflictMenuItem = addItem("Shortcut unavailable", #selector(openSettings), menu)
        conflictMenuItem.isHidden = true
        menu.addItem(.separator())

        let toolSubmenu = NSMenu(title: "Drawing Tool")
        for tool in DrawingTool.allCases {
            let item = NSMenuItem(title: tool.displayName, action: #selector(changeTool(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tool.rawValue
            toolSubmenu.addItem(item)
            toolMenuItems[tool] = item
        }
        let tools = NSMenuItem(title: "Drawing Tool", action: nil, keyEquivalent: "")
        tools.submenu = toolSubmenu
        menu.addItem(tools)

        let colorSubmenu = NSMenu(title: "Ink Color")
        for (i, color) in InkColor.palette.enumerated() {
            let item = NSMenuItem(title: InkColor.paletteNames[i], action: #selector(changeColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = i
            colorSubmenu.addItem(item)
            colorMenuItems[color] = item
        }
        let colors = NSMenuItem(title: "Ink Color", action: nil, keyEquivalent: "")
        colors.submenu = colorSubmenu
        menu.addItem(colors)

        menu.addItem(.separator())
        undoMenuItem = addItem("Undo", #selector(undo), menu)
        redoMenuItem = addItem("Redo", #selector(redo), menu)
        clearMenuItem = addItem("Clear All Screens", #selector(clearAll), menu)
        addItem("Copy Selected", #selector(copySelection), menu)
        addItem("Paste", #selector(pasteSelection), menu)
        addItem("Delete Selected", #selector(deleteSelection), menu)

        menu.addItem(.separator())
        toolbarMenuItem = addItem("Show Toolbar", #selector(toggleToolbar), menu)
        addItem("Temporarily Click Through (hold ⌘)", nil, menu).isEnabled = false
        magnifierMenuItem = addItem("Magnifier", #selector(toggleMagnifier), menu)
        zoomMenuItem = addItem("Fullscreen Zoom", #selector(toggleFullscreenZoom), menu)

        menu.addItem(.separator())
        addItem("Save Annotated Image…", #selector(saveImage), menu)
        addItem("Copy Annotated Image", #selector(copyImage), menu)
        addItem("Export Annotations as SVG…", #selector(exportSVG), menu)

        menu.addItem(.separator())
        addItem("Settings…", #selector(openSettings), menu)
        addItem("Help", #selector(showHelp), menu)
        menu.addItem(.separator())
        addItem("Quit LocalInk", #selector(quitApp), menu)

        statusItem.menu = menu
    }

    @discardableResult
    private func addItem(_ title: String, _ action: Selector?, _ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    // MARK: Shortcut dispatch

    private func handleShortcut(_ action: ShortcutAction) {
        coordinator.setPassThroughHeld(false)
        switch action {
        case .toggleDrawing: toggleDrawing()
        case .toggleHalo: toggleHalo()
        case .toggleSpotlight: toggleSpotlight()
        case .undo: undo()
        case .redo: redo()
        case .clear: clearAll()
        case .passThrough: togglePassThrough()
        case .toggleToolbar: toggleToolbar()
        }
    }

    // MARK: Mode toggles

    @objc private func toggleDrawing() {
        let state = coordinator.state
        state.annotationMode = state.drawingEnabled ? .off : .drawing
        if !state.drawingEnabled {
            state.passThroughHeld = false
        }
        coordinator.applyState()
    }

    @objc private func toggleHalo() {
        coordinator.state.haloEnabled.toggle()
        coordinator.applyState()
    }

    @objc private func toggleSpotlight() {
        coordinator.state.spotlightEnabled.toggle()
        coordinator.applyState()
    }

    @objc private func toggleWhiteboard() {
        let state = coordinator.state
        let enable = !state.whiteboardEnabled
        state.whiteboardEnabled = enable
        state.annotationMode = enable ? .drawing : .off
        coordinator.applyState()
    }

    @objc private func togglePassThrough() {
        let state = coordinator.state
        switch state.annotationMode {
        case .drawing: state.annotationMode = .temporaryPassThrough
        case .temporaryPassThrough: state.annotationMode = .drawing
        case .off: break
        }
        coordinator.applyState()
    }

    @objc private func toggleToolbar() {
        if toolbar.isVisible { hideToolbar() } else { showToolbar() }
    }

    private func showToolbar() {
        toolbar.show()
        toolbarMenuItem.title = "Hide Toolbar"
    }

    private func hideToolbar() {
        toolbar.hide()
        toolbarMenuItem.title = "Show Toolbar"
    }

    @objc private func toggleMagnifier() {
        if lens.mode == .lens { lens.stop() } else { lens.start(.lens) }
        refreshUI()
    }

    @objc private func toggleFullscreenZoom() {
        if lens.mode == .fullscreen { lens.stop() } else { lens.start(.fullscreen) }
        refreshUI()
    }

    // MARK: Tool / style

    @objc private func changeTool(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let tool = DrawingTool(rawValue: raw) else { return }
        setTool(tool)
    }

    private func setTool(_ tool: DrawingTool) {
        coordinator.state.activeTool = tool
        if tool.isMarkTool { Preferences.shared.inkTool = tool }
        coordinator.applyState()
    }

    @objc private func changeColor(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int, index < InkColor.palette.count else { return }
        setColor(InkColor.palette[index])
    }

    private func setColor(_ color: InkColor) {
        Preferences.shared.inkColor = color
        refreshUI()
    }

    private func setWidth(_ width: CGFloat) {
        Preferences.shared.inkWidth = width
    }

    // MARK: Editing

    @objc private func undo() { coordinator.undo(); refreshUI() }
    @objc private func redo() { coordinator.redo(); refreshUI() }
    @objc private func clearAll() { coordinator.clearAllDisplays(); refreshUI() }

    @objc private func copySelection() {
        guard let overlay = overlayUnderMouse() else { return }
        coordinator.copySelection(from: overlay)
    }

    @objc private func pasteSelection() {
        guard let overlay = overlayUnderMouse() else { return }
        coordinator.paste(on: overlay)
    }

    @objc private func deleteSelection() {
        guard let overlay = overlayUnderMouse() else { return }
        overlay.deleteSelected()
    }

    // MARK: Pass-through monitor

    private func installPassThroughMonitor() {
        passThroughMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if event.type == .flagsChanged {
                let held = event.modifierFlags.contains(.command)
                let drawing = self.coordinator.state.drawingEnabled
                self.coordinator.setPassThroughHeld(held && drawing)
            }
            return event
        }
    }

    // MARK: Export

    @objc private func saveImage() {
        guard ensureCaptureAccess() else { return }
        guard let screen = screenUnderMouse() else { return }
        guard let url = promptSaveURL(defaultName: defaultFilename()) else { return }
        Task { await self.exportAnnotatedImage(screen: screen, url: url) }
    }

    @objc private func copyImage() {
        guard ensureCaptureAccess() else { return }
        guard let screen = screenUnderMouse() else { return }
        Task { await self.exportAnnotatedImage(screen: screen, url: nil) }
    }

    @objc private func exportSVG() {
        guard let screen = screenUnderMouse() else { return }
        guard let overlay = coordinator.overlay(for: screen.displayID) else { return }
        let svg = ExportService.svgString(for: overlay.marks, displayHeight: screen.frame.height)
        guard let url = promptSaveURL(defaultName: "LocalInk-annotations.svg") else { return }
        do {
            try svg.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError("Could not write the SVG file.")
        }
    }

    private func exportAnnotatedImage(screen: NSScreen, url: URL?) async {
        do {
            let content = try await CaptureService.shared.shareableContent()
            guard let display = CaptureService.shared.display(screen.displayID, in: content) else {
                presentError("Could not find the display.")
                return
            }
            let filter = CaptureService.shared.filter(display: display, excluding: localWindowIDs(), in: content)
            let image = try await CaptureService.shared.captureImage(filter: filter)
            let overlay = coordinator.overlay(for: screen.displayID)
            let scale = CGFloat(image.width) / screen.frame.width
            let annotated = ExportService.renderAnnotatedImage(screenshot: image,
                                                               annotations: overlay?.marks ?? [],
                                                               scale: scale)
            if let url {
                try ExportService.writePNG(annotated, to: url)
                presentStatus("Saved annotated image.")
            } else {
                ExportService.copyToClipboard(annotated)
                presentStatus("Copied annotated image to the clipboard.")
            }
        } catch {
            presentError("Capture failed: \(error.localizedDescription)")
        }
    }

    // MARK: Helpers

    private func localWindowIDs() -> Set<CGWindowID> {
        var ids = Set<CGWindowID>()
        for window in coordinator.windows {
            ids.insert(CGWindowID(window.windowNumber))
        }
        if toolbar.isVisible {
            ids.insert(CGWindowID(toolbar.panel.windowNumber))
        }
        return ids
    }

    private func screenUnderMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func overlayUnderMouse() -> DrawingOverlay? {
        guard let screen = screenUnderMouse() else { return nil }
        return coordinator.overlay(for: screen.displayID)
    }

    private func defaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "LocalInk-\(formatter.string(from: Date())).png"
    }

    private func promptSaveURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        if let folder = Preferences.shared.exportFolder {
            panel.directoryURL = URL(fileURLWithPath: folder)
        }
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func ensureCaptureAccess() -> Bool {
        switch CaptureService.shared.access {
        case .allowed: return true
        case .unchecked:
            _ = CaptureService.shared.requestAccess()
            if CaptureService.shared.access == .allowed { return true }
            presentCapturePermissionAlert()
            return false
        case .denied:
            presentCapturePermissionAlert()
            return false
        }
    }

    private func presentCapturePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Zoom and image export capture your display and need Screen Recording permission. Enable LocalInk in System Settings → Privacy & Security → Screen Recording, then try again. Drawing, halo, and spotlight keep working without it."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func presentError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "LocalInk"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func presentStatus(_ message: String) {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.refreshUI()
                }
            }
        }
    }

    // MARK: Settings / help

    @objc private func openSettings() { settings.show() }

    @objc private func showHelp() {
        showFirstRunHelp()
    }

    private func showFirstRunHelpIfNeeded() {
        let key = "LocalInk.firstRunHelpShown"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        showFirstRunHelp()
    }

    private func showFirstRunHelp() {
        let alert = NSAlert()
        alert.messageText = "Welcome to LocalInk"
        alert.informativeText = """
        • Click the pencil icon in the menu bar for tools, colors, and effects.
        • Toggle drawing with \(Preferences.shared.shortcuts[.toggleDrawing]?.displayString ?? "Control-Option-D"), then draw on any screen.
        • Toggle the cursor halo and spotlight to call out a detail while the app underneath stays clickable.
        • When drawing is on, hold ⌘ to temporarily click through to the app underneath.
        • Zoom and image export are optional and need Screen Recording permission; everything else works locally with no network or account.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it")
        alert.runModal()
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}
