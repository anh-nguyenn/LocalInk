import AppKit

// MARK: - Floating toolbar

// A compact floating palette that floats above the annotation overlay. Only the
// toolbar's own area accepts input; the space around it keeps the current mode.
final class ToolbarController {
    let panel: NSPanel
    weak var coordinator: OverlayCoordinator?

    var onTool: ((DrawingTool) -> Void)?
    var onColor: ((InkColor) -> Void)?
    var onWidth: ((CGFloat) -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onClear: (() -> Void)?
    var onToggleHalo: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onToggleWhiteboard: (() -> Void)?
    var onPassThrough: (() -> Void)?
    var onHide: (() -> Void)?

    private var toolButtons: [DrawingTool: NSButton] = [:]
    private var colorButtons: [InkColor: NSButton] = [:]
    private var widthSlider: NSSlider!
    private var widthLabel: NSTextField!
    private var haloButton: NSButton!
    private var spotlightButton: NSButton!
    private var whiteboardButton: NSButton!
    private var passThroughButton: NSButton!
    private var undoButton: NSButton!
    private var redoButton: NSButton!

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 108),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.level = .screenSaver + 1
        panel.isOpaque = false
        panel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.92)
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        build()
    }

    private func build() {
        let tools = DrawingTool.paletteOrder
        let toolRow = NSStackView()
        toolRow.orientation = .horizontal
        toolRow.spacing = 4
        for tool in tools {
            let button = symbolButton(tool.systemSymbol, title: tool.displayName)
            button.target = self
            button.action = #selector(toolTapped(_:))
            button.tag = tools.firstIndex(of: tool) ?? 0
            toolButtons[tool] = button
            toolRow.addArrangedSubview(button)
        }
        toolRow.addArrangedSubview(NSView())

        let colorRow = NSStackView()
        colorRow.orientation = .horizontal
        colorRow.spacing = 4
        for (i, color) in InkColor.palette.enumerated() {
            let button = NSButton(image: swatchImage(color), target: self, action: #selector(colorTapped(_:)))
            button.bezelStyle = .smallSquare
            button.isBordered = true
            button.toolTip = InkColor.paletteNames[i]
            button.tag = i
            colorButtons[color] = button
            colorRow.addArrangedSubview(button)
        }
        colorRow.addArrangedSubview(NSView())

        widthLabel = NSTextField(labelWithString: "4 pt")
        widthLabel.alignment = .center
        widthLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        widthSlider = NSSlider(value: 4, minValue: 0.5, maxValue: 40, target: self, action: #selector(widthChanged(_:)))
        widthSlider.controlSize = .small
        widthSlider.widthAnchor.constraint(equalToConstant: 120).isActive = true

        undoButton = symbolButton("arrow.uturn.backward", title: "Undo")
        undoButton.target = self
        undoButton.action = #selector(undoTapped(_:))
        redoButton = symbolButton("arrow.uturn.forward", title: "Redo")
        redoButton.target = self
        redoButton.action = #selector(redoTapped(_:))

        haloButton = symbolButton("circle.circle", title: "Halo")
        haloButton.target = self
        haloButton.action = #selector(haloTapped(_:))
        spotlightButton = symbolButton("lightbulb", title: "Spotlight")
        spotlightButton.target = self
        spotlightButton.action = #selector(spotlightTapped(_:))
        whiteboardButton = symbolButton("rectangle.on.rectangle", title: "Whiteboard")
        whiteboardButton.target = self
        whiteboardButton.action = #selector(whiteboardTapped(_:))

        passThroughButton = symbolButton("hand.raised", title: "Click Through")
        passThroughButton.target = self
        passThroughButton.action = #selector(passThroughTapped(_:))

        let clearButton = symbolButton("trash", title: "Clear")
        clearButton.target = self
        clearButton.action = #selector(clearTapped(_:))
        let closeButton = symbolButton("xmark.circle", title: "Hide Toolbar")
        closeButton.target = self
        closeButton.action = #selector(closeTapped(_:))

        let actionRow = NSStackView()
        actionRow.orientation = .horizontal
        actionRow.spacing = 4
        actionRow.addArrangedSubview(widthLabel)
        actionRow.addArrangedSubview(widthSlider)
        actionRow.addArrangedSubview(undoButton)
        actionRow.addArrangedSubview(redoButton)
        actionRow.addArrangedSubview(clearButton)
        actionRow.addArrangedSubview(haloButton)
        actionRow.addArrangedSubview(spotlightButton)
        actionRow.addArrangedSubview(whiteboardButton)
        actionRow.addArrangedSubview(passThroughButton)
        actionRow.addArrangedSubview(closeButton)
        actionRow.addArrangedSubview(NSView())

        let root = NSStackView(views: [toolRow, colorRow, actionRow])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        root.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(root)
        panel.contentView = content
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
    }

    private func symbolButton(_ symbol: String, title: String) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .texturedRounded
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        button.imagePosition = .imageOnly
        button.setButtonType(.toggle)
        button.toolTip = title
        button.controlSize = .regular
        return button
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

    // MARK: Actions

    @objc private func toolTapped(_ sender: NSButton) {
        let tools = DrawingTool.paletteOrder
        guard sender.tag < tools.count else { return }
        onTool?(tools[sender.tag])
    }

    @objc private func colorTapped(_ sender: NSButton) {
        guard sender.tag < InkColor.palette.count else { return }
        onColor?(InkColor.palette[sender.tag])
    }

    @objc private func widthChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        widthLabel.stringValue = String(format: "%.1f pt", Double(value))
        onWidth?(value)
    }

    @objc private func undoTapped(_ sender: Any) { onUndo?() }
    @objc private func redoTapped(_ sender: Any) { onRedo?() }
    @objc private func haloTapped(_ sender: Any) { onToggleHalo?() }
    @objc private func spotlightTapped(_ sender: Any) { onToggleSpotlight?() }
    @objc private func whiteboardTapped(_ sender: Any) { onToggleWhiteboard?() }
    @objc private func passThroughTapped(_ sender: Any) { onPassThrough?() }
    @objc private func clearTapped(_ sender: Any) { onClear?() }
    @objc private func closeTapped(_ sender: Any) { onHide?() }

    // MARK: Presentation

    func show() {
        positionNearMouse()
        panel.orderFrontRegardless()
        refresh()
    }

    func hide() {
        panel.orderOut(nil)
    }

    var isVisible: Bool { panel.isVisible }

    private func positionNearMouse() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        let margin: CGFloat = 20
        var x = mouse.x - panel.frame.width / 2
        var y = mouse.y - panel.frame.height - 40
        x = max(screen.frame.minX + margin, min(x, screen.frame.maxX - panel.frame.width - margin))
        y = max(screen.frame.minY + margin, min(y, screen.frame.maxY - panel.frame.height - margin))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: Refresh

    func refresh() {
        guard let coordinator else { return }
        let state = coordinator.state
        for (tool, button) in toolButtons {
            button.state = state.activeTool == tool ? .on : .off
        }
        let selectedColor = Preferences.shared.inkColor
        for (color, button) in colorButtons {
            button.state = color == selectedColor ? .on : .off
        }
        widthSlider.doubleValue = Double(Preferences.shared.inkWidth)
        widthLabel.stringValue = String(format: "%.1f pt", Double(Preferences.shared.inkWidth))
        haloButton.state = state.haloEnabled ? .on : .off
        spotlightButton.state = state.spotlightEnabled ? .on : .off
        whiteboardButton.state = state.whiteboardEnabled ? .on : .off
        passThroughButton.state = (state.annotationMode == .temporaryPassThrough) ? .on : .off
        undoButton.isEnabled = coordinator.undoStack.canUndo
        redoButton.isEnabled = coordinator.undoStack.canRedo
    }
}
