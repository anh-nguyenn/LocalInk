import AppKit

// MARK: - Control window

// A visible, non-modal home for the app. LocalInk is a menu-bar utility, but a
// blank launch is easy to mistake for a failed one, so this window explains the
// menu-bar icon and offers a direct Start Drawing action.
final class ControlWindowController: NSObject, NSWindowDelegate {
    var onStartDrawing: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private var window: NSWindow?
    private var startButton: NSButton?
    private var statusLabel: NSTextField?

    func show(drawingEnabled: Bool) {
        buildIfNeeded()
        update(drawingEnabled: drawingEnabled)
        guard let window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        Self.activateApp()
    }

    func close() {
        window?.close()
    }

    func update(drawingEnabled: Bool) {
        startButton?.title = drawingEnabled ? "Drawing Is On — Turn It Off" : "Start Drawing"
        statusLabel?.stringValue = drawingEnabled
            ? "Drawing is on. Draw anywhere, then turn it off from the menu bar."
            : "LocalInk is ready. Start drawing over any app on your desktop."
    }

    private func buildIfNeeded() {
        guard window == nil else { return }

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 430),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = "LocalInk"
        window.isReleasedWhenClosed = false
        window.level = .screenSaver + 1
        window.delegate = self

        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let title = NSTextField(labelWithString: "LocalInk")
        title.font = NSFont.systemFont(ofSize: 26, weight: .bold)

        let subtitle = NSTextField(labelWithString: "Draw on anything. Interrupt nothing.")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor

        let heading = NSStackView(views: [title, subtitle])
        heading.orientation = .vertical
        heading.alignment = .leading
        heading.spacing = 2

        let header = NSStackView(views: [icon, heading])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 14

        let statusLabel = NSTextField(wrappingLabelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.maximumNumberOfLines = 2
        self.statusLabel = statusLabel

        let instructions = NSTextField(wrappingLabelWithString: """
        LocalInk lives in your menu bar. Look for the pencil icon near the clock — \
        click it for tools, colors, effects, export, and settings.

        You can also toggle drawing at any time with Control-Option-D. \
        While drawing, hold Command to click through to the app underneath.
        """)
        instructions.font = NSFont.systemFont(ofSize: 12)
        instructions.textColor = .secondaryLabelColor

        let startButton = NSButton(title: "Start Drawing", target: self, action: #selector(startDrawing))
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.keyEquivalent = "\r"
        startButton.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        self.startButton = startButton

        let settingsButton = NSButton(title: "Settings…", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .large

        let primaryRow = NSStackView(views: [startButton, settingsButton])
        primaryRow.orientation = .horizontal
        primaryRow.spacing = 10

        let showOnLaunch = NSButton(checkboxWithTitle: "Show this window when LocalInk starts at login",
                                    target: self, action: #selector(showOnLaunchToggled(_:)))
        showOnLaunch.state = Preferences.shared.showControlWindow ? .on : .off

        let dockIcon = NSButton(checkboxWithTitle: "Show LocalInk in the Dock",
                                target: self, action: #selector(dockToggled(_:)))
        dockIcon.state = Preferences.shared.showDockIcon ? .on : .off

        let quitButton = NSButton(title: "Quit LocalInk", target: self, action: #selector(quit))
        quitButton.bezelStyle = .inline

        let root = NSStackView(views: [header, statusLabel, instructions,
                                       primaryRow, showOnLaunch, dockIcon, quitButton])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 22, left: 24, bottom: 22, right: 24)
        root.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
        window.contentView = content
        self.window = window
    }

    @objc private func startDrawing() {
        onStartDrawing?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func quit() {
        onQuit?()
    }

    @objc private func showOnLaunchToggled(_ sender: NSButton) {
        Preferences.shared.showControlWindow = sender.state == .on
    }

    @objc private func dockToggled(_ sender: NSButton) {
        let enabled = sender.state == .on
        Preferences.shared.showDockIcon = enabled
        NSApp.setActivationPolicy(enabled ? .regular : .accessory)
    }

    static func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        // Cooperative activation can decline the request while another app is
        // frontmost. Starting drawing from a menu or global shortcut must still
        // make LocalInk key so Escape and the single-key tool shortcuts work.
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
}
