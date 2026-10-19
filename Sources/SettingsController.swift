import AppKit
import Carbon
import ServiceManagement
import ObjectiveC

// MARK: - Shortcut recorder

final class ShortcutRecorderButton: NSButton {
    var onRecord: ((Shortcut) -> Void)?
    var shortcut: Shortcut? {
        didSet {
            title = shortcut?.displayString ?? "Click to record"
        }
    }
    private var monitor: Any?
    private var recording = false

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(beginRecording)
        title = "Click to record"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func beginRecording() {
        guard !recording else { return }
        recording = true
        title = "Press keys…"
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.capture(event)
            return nil
        }
    }

    private func capture(_ event: NSEvent) {
        finishRecording()
        var modifiers: UInt32 = 0
        if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
        let shortcut = Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        self.shortcut = shortcut
        onRecord?(shortcut)
    }

    private func finishRecording() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
    }
}

// MARK: - Settings pane

final class SettingsPaneViewController: NSViewController {
    let paneTitle: String
    let iconName: String
    let root: NSStackView
    private let scroll: NSScrollView

    init(title: String, iconName: String) {
        self.paneTitle = title
        self.iconName = iconName
        self.root = NSStackView()
        self.scroll = NSScrollView()
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        root.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            root.topAnchor.constraint(equalTo: container.topAnchor),
            root.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        scroll.documentView = container
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.documentView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor)
        ])
        self.view = scroll
    }
}

// MARK: - Settings window

final class SettingsController: NSObject {
    weak var coordinator: OverlayCoordinator?
    var onChange: (() -> Void)?

    private var window: NSWindow!
    private var tabViewController: NSTabViewController!
    private var panes: [SettingsPaneViewController] = []
    private var zoomStatusLabel: NSTextField?

    func show() {
        build()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func build() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "LocalInk Settings"
        window.isReleasedWhenClosed = false
        window.level = .screenSaver + 1

        tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar

        panes = [
            makeGeneralPane(), makeDrawingPane(), makeCursorPane(), makeSpotlightPane(),
            makeWhiteboardPane(), makeZoomPane(), makeShortcutsPane(), makeExportPane(),
            makeAboutPane()
        ]
        for pane in panes {
            let item = NSTabViewItem(viewController: pane)
            item.label = pane.paneTitle
            item.image = NSImage(systemSymbolName: pane.iconName, accessibilityDescription: pane.paneTitle)
            tabViewController.addTabViewItem(item)
        }

        window.contentViewController = tabViewController
    }

    // MARK: Helpers

    private func section(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.boldSystemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func row(_ title: String, _ control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 150).isActive = true
        let stack = NSStackView(views: [label, control])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        return stack
    }

    private func sliderRow(_ title: String, min: Double, max: Double, value: Double,
                           format: String, onChange: @escaping (Double) -> Void) -> NSStackView {
        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: nil, action: nil)
        let valueLabel = NSTextField(labelWithString: String(format: format, value))
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        valueLabel.alignment = .left
        valueLabel.widthAnchor.constraint(equalToConstant: 64).isActive = true
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        slider.localInkAttachment = SliderBinding(onChange: onChange, format: format, valueLabel: valueLabel)
        let label = NSTextField(labelWithString: title)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 150).isActive = true
        let stack = NSStackView(views: [label, slider, valueLabel])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        return stack
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        guard let binding = sender.localInkAttachment as? SliderBinding else { return }
        let value = sender.doubleValue
        binding.valueLabel.stringValue = String(format: binding.format, value)
        binding.onChange(value)
        onChange?()
    }

    private func colorRow(selected: InkColor, colors: [InkColor], names: [String],
                          onSelect: @escaping (InkColor) -> Void) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        for (i, color) in colors.enumerated() {
            let button = NSButton()
            button.bezelStyle = .smallSquare
            button.isBordered = true
            button.image = swatchImage(color)
            button.toolTip = names[i]
            button.tag = i
            button.target = self
            button.action = #selector(swatchTapped(_:))
            button.localInkAttachment = SwatchBinding(colors: colors, onSelect: onSelect)
            button.state = (color == selected) ? .on : .off
            stack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(NSView())
        return stack
    }

    @objc private func swatchTapped(_ sender: NSButton) {
        guard let binding = sender.localInkAttachment as? SwatchBinding else { return }
        let index = sender.tag
        guard index < binding.colors.count else { return }
        binding.onSelect(binding.colors[index])
        onChange?()
    }

    private func swatchImage(_ color: InkColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        let path = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14))
        color.nsColor.setFill()
        path.fill()
        NSColor.black.withAlphaComponent(0.25).setStroke()
        path.lineWidth = 1
        path.stroke()
        image.unlockFocus()
        return image
    }

    // MARK: Panes

    private func makeGeneralPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "General", iconName: "gearshape")
        pane.root.addArrangedSubview(section("Startup"))
        let loginButton = NSButton(checkboxWithTitle: "Launch LocalInk at login", target: self, action: #selector(loginToggled(_:)))
        loginButton.state = Preferences.shared.launchAtLogin ? .on : .off
        pane.root.addArrangedSubview(loginButton)

        let dockButton = NSButton(checkboxWithTitle: "Show LocalInk in the Dock", target: self, action: #selector(dockToggled(_:)))
        dockButton.state = Preferences.shared.showDockIcon ? .on : .off
        pane.root.addArrangedSubview(dockButton)

        let retention = NSPopUpButton(frame: .zero, pullsDown: false)
        retention.addItems(withTitles: ["Until I quit LocalInk", "Until I clear the screen"])
        retention.tag = 1
        retention.target = self
        retention.action = #selector(retentionChanged(_:))
        retention.selectItem(at: Preferences.shared.sessionRetention == "untilClear" ? 1 : 0)
        pane.root.addArrangedSubview(row("Session drawings", retention))
        pane.root.addArrangedSubview(section("Menu bar"))
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "LocalInk runs as a menu-bar app. Use the pencil icon to access tools, effects, and settings."))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeDrawingPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Drawing", iconName: "pencil.tip")
        let prefs = Preferences.shared
        pane.root.addArrangedSubview(section("Tool"))
        let toolPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for tool in DrawingTool.allCases where tool.isMarkTool {
            toolPopup.addItem(withTitle: tool.displayName)
        }
        toolPopup.selectItem(withTitle: prefs.inkTool.displayName)
        toolPopup.target = self
        toolPopup.action = #selector(toolChanged(_:))
        pane.root.addArrangedSubview(row("Default tool", toolPopup))

        pane.root.addArrangedSubview(section("Color"))
        pane.root.addArrangedSubview(colorRow(selected: prefs.inkColor, colors: InkColor.palette,
                                              names: InkColor.paletteNames, onSelect: { Preferences.shared.inkColor = $0 }))

        pane.root.addArrangedSubview(sliderRow("Stroke width", min: 0.5, max: 40, value: Double(prefs.inkWidth),
                                               format: "%.1f pt", onChange: { Preferences.shared.inkWidth = CGFloat($0) }))
        pane.root.addArrangedSubview(sliderRow("Opacity", min: 0.05, max: 1, value: Double(prefs.inkOpacity),
                                               format: "%.0f%%", onChange: { Preferences.shared.inkOpacity = CGFloat($0) }))
        pane.root.addArrangedSubview(sliderRow("Auto-erase delay", min: 0, max: 60, value: Double(prefs.autoEraseDelay),
                                               format: "%.0f s", onChange: { Preferences.shared.autoEraseDelay = $0 }))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeCursorPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Cursor", iconName: "cursorarrow.rays")
        let prefs = Preferences.shared
        pane.root.addArrangedSubview(section("Halo"))
        let ringOnly = NSButton(checkboxWithTitle: "Ring only (hide center dot)", target: self, action: #selector(ringOnlyToggled(_:)))
        ringOnly.state = prefs.haloRingOnly ? .on : .off
        pane.root.addArrangedSubview(ringOnly)
        pane.root.addArrangedSubview(colorRow(selected: prefs.haloColor, colors: InkColor.palette,
                                              names: InkColor.paletteNames, onSelect: { Preferences.shared.haloColor = $0 }))
        pane.root.addArrangedSubview(sliderRow("Size", min: 8, max: 120, value: Double(prefs.haloSize),
                                               format: "%.0f pt", onChange: { Preferences.shared.haloSize = CGFloat($0) }))
        pane.root.addArrangedSubview(sliderRow("Opacity", min: 0.05, max: 1, value: Double(prefs.haloOpacity),
                                               format: "%.0f%%", onChange: { Preferences.shared.haloOpacity = CGFloat($0) }))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeSpotlightPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Spotlight", iconName: "lightbulb")
        let prefs = Preferences.shared
        pane.root.addArrangedSubview(section("Aperture"))
        pane.root.addArrangedSubview(sliderRow("Size", min: 40, max: 400, value: Double(prefs.spotlightSize),
                                               format: "%.0f pt", onChange: { Preferences.shared.spotlightSize = CGFloat($0) }))
        pane.root.addArrangedSubview(sliderRow("Dim level", min: 0.1, max: 0.95, value: Double(prefs.spotlightDimLevel),
                                               format: "%.0f%%", onChange: { Preferences.shared.spotlightDimLevel = CGFloat($0) }))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeWhiteboardPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Whiteboard", iconName: "rectangle.on.rectangle")
        let prefs = Preferences.shared
        pane.root.addArrangedSubview(section("Background"))
        pane.root.addArrangedSubview(colorRow(selected: prefs.whiteboardColor, colors: InkColor.palette,
                                              names: InkColor.paletteNames, onSelect: { Preferences.shared.whiteboardColor = $0 }))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeZoomPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Zoom & Capture", iconName: "magnifyingglass")
        let prefs = Preferences.shared
        pane.root.addArrangedSubview(section("Screen recording permission"))
        let statusLabel = NSTextField(wrappingLabelWithString: CaptureService.shared.accessText())
        zoomStatusLabel = statusLabel
        pane.root.addArrangedSubview(statusLabel)
        let requestButton = NSButton(title: "Request Permission", target: self, action: #selector(requestPermissionTapped(_:)))
        pane.root.addArrangedSubview(requestButton)
        pane.root.addArrangedSubview(sliderRow("Lens size", min: 100, max: 500, value: Double(prefs.lensSize),
                                               format: "%.0f pt", onChange: { Preferences.shared.lensSize = CGFloat($0) }))
        pane.root.addArrangedSubview(sliderRow("Zoom factor", min: 1.5, max: 6, value: Double(prefs.zoomFactor),
                                               format: "%.1f×", onChange: { Preferences.shared.zoomFactor = CGFloat($0) }))
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "Zoom and capture work only after you grant Screen Recording permission. Drawing, halo, and spotlight never need it."))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeShortcutsPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Shortcuts", iconName: "keyboard")
        let shortcuts = Preferences.shared.shortcuts
        let ordered: [ShortcutAction] = [.toggleDrawing, .toggleHalo, .toggleSpotlight, .undo, .redo, .clear, .passThrough, .toggleToolbar]
        for action in ordered {
            let recorder = ShortcutRecorderButton()
            recorder.shortcut = shortcuts[action]
            recorder.onRecord = { [weak self] newShortcut in
                guard let self else { return }
                var updated = Preferences.shared.shortcuts
                updated[action] = newShortcut
                Preferences.shared.shortcuts = updated
                self.coordinator?.reloadHotkeys?()
                self.onChange?()
            }
            let rowStack = row(action.displayName, recorder)
            pane.root.addArrangedSubview(rowStack)
        }
        let resetButton = NSButton(title: "Restore Default Shortcuts", target: self, action: #selector(resetShortcutsTapped(_:)))
        pane.root.addArrangedSubview(resetButton)
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "Shortcuts are global and work while LocalInk is in the background. A conflicting combination is ignored and reported in the menu."))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeExportPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "Export", iconName: "square.and.arrow.up")
        pane.root.addArrangedSubview(section("Save location"))
        let folderLabel = NSTextField(wrappingLabelWithString: Preferences.shared.exportFolder ?? "Not set — you will be asked each time")
        folderLabel.tag = 10
        pane.root.addArrangedSubview(folderLabel)
        let chooseButton = NSButton(title: "Choose Folder…", target: self, action: #selector(chooseFolderTapped(_:)))
        pane.root.addArrangedSubview(chooseButton)
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "Exported images combine the captured display with your committed annotations and never include LocalInk's own controls."))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    private func makeAboutPane() -> SettingsPaneViewController {
        let pane = SettingsPaneViewController(title: "About", iconName: "info.circle")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let name = NSTextField(labelWithString: "LocalInk \(version)")
        name.font = NSFont.boldSystemFont(ofSize: 16)
        pane.root.addArrangedSubview(name)
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "An offline, native macOS menu-bar app for drawing and directing attention on top of your desktop during presentations, lessons, and recordings."))
        pane.root.addArrangedSubview(section("Privacy"))
        pane.root.addArrangedSubview(NSTextField(wrappingLabelWithString: "LocalInk works locally with no account, telemetry, or network connection. Screen content is captured only when you start zoom or export, and only to a location you choose."))
        pane.root.addArrangedSubview(NSView())
        return pane
    }

    // MARK: Actions

    @objc private func loginToggled(_ sender: NSButton) {
        let enable = sender.state == .on
        let service = SMAppService.mainApp
        do {
            if enable { try service.register() } else { try service.unregister() }
            Preferences.shared.launchAtLogin = enable
        } catch {
            sender.state = Preferences.shared.launchAtLogin ? .on : .off
            NSSound.beep()
        }
    }

    @objc private func dockToggled(_ sender: NSButton) {
        let enable = sender.state == .on
        Preferences.shared.showDockIcon = enable
        NSApp.setActivationPolicy(enable ? .regular : .accessory)
    }

    @objc private func retentionChanged(_ sender: NSPopUpButton) {
        Preferences.shared.sessionRetention = sender.indexOfSelectedItem == 1 ? "untilClear" : "untilQuit"
    }

    @objc private func toolChanged(_ sender: NSPopUpButton) {
        let title = sender.titleOfSelectedItem ?? "Pen"
        if let tool = DrawingTool.allCases.first(where: { $0.displayName == title }) {
            Preferences.shared.inkTool = tool
            coordinator?.state.activeTool = tool
            onChange?()
        }
    }

    @objc private func ringOnlyToggled(_ sender: NSButton) {
        Preferences.shared.haloRingOnly = sender.state == .on
        onChange?()
    }

    @objc private func requestPermissionTapped(_ sender: NSButton) {
        _ = CaptureService.shared.requestAccess()
        zoomStatusLabel?.stringValue = CaptureService.shared.accessText()
        onChange?()
    }

    @objc private func resetShortcutsTapped(_ sender: NSButton) {
        Preferences.shared.resetShortcuts()
        coordinator?.reloadHotkeys?()
        onChange?()
        show()
    }

    @objc private func chooseFolderTapped(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            Preferences.shared.exportFolder = url.path
        }
    }
}

// MARK: - Bindings

private final class SliderBinding {
    let onChange: (Double) -> Void
    let format: String
    let valueLabel: NSTextField
    init(onChange: @escaping (Double) -> Void, format: String, valueLabel: NSTextField) {
        self.onChange = onChange
        self.format = format
        self.valueLabel = valueLabel
    }
}

private final class SwatchBinding {
    let colors: [InkColor]
    let onSelect: (InkColor) -> Void
    init(colors: [InkColor], onSelect: @escaping (InkColor) -> Void) {
        self.colors = colors
        self.onSelect = onSelect
    }
}

private var localInkAssociationKey: UInt8 = 0

extension NSObject {
    var localInkAttachment: Any? {
        get { objc_getAssociatedObject(self, &localInkAssociationKey) }
        set { objc_setAssociatedObject(self, &localInkAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension CaptureService {
    func accessText() -> String {
        switch access {
        case .allowed: return "Screen Recording permission is granted."
        case .denied: return "Screen Recording permission was denied. Enable it in System Settings → Privacy & Security → Screen Recording."
        case .unchecked: return "Screen Recording permission has not been requested yet."
        }
    }
}
