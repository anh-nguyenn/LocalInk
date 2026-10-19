import AppKit
import Carbon

// LocalInk is a self-contained, offline macOS screen annotation overlay.
// No screen capture, microphone, network, or accessibility permission is needed for this MVP.

enum DrawingTool: String, CaseIterable {
    case pen = "Pen"
    case arrow = "Arrow"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
}

struct Mark {
    var tool: DrawingTool
    var points: [NSPoint]
    var color: NSColor
    var thickness: CGFloat
}

final class DrawingOverlay: NSView {
    var drawingEnabled = false
    var showHalo = false
    var showSpotlight = false
    var tool: DrawingTool = .pen
    var inkColor: NSColor = .systemRed
    var inkWidth: CGFloat = 4
    var cursorPoint = NSPoint(x: -10000, y: -10000)

    private(set) var marks: [Mark] = []
    private var currentMark: Mark?
    var onNewMark: (() -> Void)?

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.setFill()
        NSBezierPath(rect: dirtyRect).fill()

        if bounds.contains(cursorPoint) && showSpotlight {
            let shade = NSBezierPath(rect: bounds)
            let hole = NSRect(x: cursorPoint.x - 105, y: cursorPoint.y - 105,
                              width: 210, height: 210)
            shade.appendOval(in: hole)
            shade.windingRule = .evenOdd
            NSColor.black.withAlphaComponent(0.60).setFill()
            shade.fill()
        }

        for mark in marks { drawMark(mark) }
        if let currentMark { drawMark(currentMark) }

        if bounds.contains(cursorPoint) && showHalo {
            let ring = NSBezierPath(ovalIn: NSRect(x: cursorPoint.x - 30,
                                                    y: cursorPoint.y - 30,
                                                    width: 60, height: 60))
            ring.lineWidth = 4
            NSColor.systemYellow.withAlphaComponent(0.85).setStroke()
            ring.stroke()
            let center = NSBezierPath(ovalIn: NSRect(x: cursorPoint.x - 4,
                                                      y: cursorPoint.y - 4,
                                                      width: 8, height: 8))
            NSColor.systemYellow.setFill()
            center.fill()
        }
    }

    private func drawMark(_ mark: Mark) {
        guard let first = mark.points.first else { return }
        let last = mark.points.last ?? first
        let path = NSBezierPath()
        path.lineWidth = mark.thickness
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        switch mark.tool {
        case .pen:
            path.move(to: first)
            for pt in mark.points.dropFirst() { path.line(to: pt) }
            if mark.points.count == 1 { path.line(to: NSPoint(x: first.x + 0.01, y: first.y + 0.01)) }
        case .arrow:
            path.move(to: first)
            path.line(to: last)
            let angle = atan2(last.y - first.y, last.x - first.x)
            let size: CGFloat = 16
            let wing: CGFloat = .pi / 6
            path.move(to: NSPoint(x: last.x - size * cos(angle - wing),
                                  y: last.y - size * sin(angle - wing)))
            path.line(to: last)
            path.line(to: NSPoint(x: last.x - size * cos(angle + wing),
                                  y: last.y - size * sin(angle + wing)))
        case .rectangle, .ellipse:
            let rect = NSRect(x: min(first.x, last.x), y: min(first.y, last.y),
                              width: abs(last.x - first.x), height: abs(last.y - first.y))
            if mark.tool == .rectangle { path.appendRect(rect) }
            else { path.appendOval(in: rect) }
        }
        mark.color.setStroke()
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        guard drawingEnabled else { return }
        let pt = convert(event.locationInWindow, from: nil)
        currentMark = Mark(tool: tool, points: [pt], color: inkColor, thickness: inkWidth)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard drawingEnabled, currentMark != nil else { return }
        let pt = convert(event.locationInWindow, from: nil)
        if tool == .pen { currentMark?.points.append(pt) }
        else if currentMark!.points.count == 1 { currentMark?.points.append(pt) }
        else { currentMark?.points[1] = pt }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard drawingEnabled, var mark = currentMark else { return }
        if mark.points.count == 1 {
            mark.points.append(convert(event.locationInWindow, from: nil))
        }
        marks.append(mark)
        currentMark = nil
        onNewMark?()
        needsDisplay = true
    }

    func undo() {
        if !marks.isEmpty { marks.removeLast() }
        currentMark = nil
        needsDisplay = true
    }

    func clear() {
        marks.removeAll()
        currentMark = nil
        needsDisplay = true
    }
}

final class OverlayController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var windows: [NSPanel] = []
    private var overlays: [DrawingOverlay] = []
    private var mouseTimer: Timer?
    private var drawingEnabled = false
    private var showHalo = false
    private var showSpotlight = false
    private var selectedTool: DrawingTool = .pen
    private var selectedColor: NSColor = .systemRed
    private weak var lastEdited: DrawingOverlay?
    private var hotKeyHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenu()
        makeWindows()
        installHotkeys()
        mouseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.refreshCursor()
        }
        NotificationCenter.default.addObserver(self,
            selector: #selector(displaysChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTimer?.invalidate()
        if let handler = hotKeyHandler { RemoveEventHandler(handler) }
        for hotkey in hotKeyRefs { UnregisterEventHotKey(hotkey) }
    }

    private func makeWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        overlays.removeAll()
        lastEdited = nil
        for screen in NSScreen.screens {
            let panel = NSPanel(contentRect: screen.frame,
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
            panel.level = .statusBar
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.isFloatingPanel = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.ignoresMouseEvents = !drawingEnabled
            panel.isReleasedWhenClosed = false
            let overlay = DrawingOverlay(frame: NSRect(origin: .zero, size: screen.frame.size))
            overlay.autoresizingMask = [.width, .height]
            overlay.drawingEnabled = drawingEnabled
            overlay.showHalo = showHalo
            overlay.showSpotlight = showSpotlight
            overlay.tool = selectedTool
            overlay.inkColor = selectedColor
            overlay.onNewMark = { [weak self, weak overlay] in
                self?.lastEdited = overlay
            }
            panel.contentView = overlay
            panel.orderFrontRegardless()
            windows.append(panel)
            overlays.append(overlay)
        }
    }

    @objc private func displaysChanged() { makeWindows() }

    private func refreshCursor() {
        guard showHalo || showSpotlight else { return }
        let location = NSEvent.mouseLocation
        for (window, overlay) in zip(windows, overlays) {
            overlay.cursorPoint = overlay.convert(window.convertPoint(fromScreen: location), from: nil)
            overlay.needsDisplay = true
        }
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "LocalInk")
            button.toolTip = "LocalInk — offline screen annotation"
        }
        let menu = NSMenu(title: "LocalInk")
        menu.addItem(NSMenuItem(title: "LocalInk — Local Screen Overlay", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        addMenuItem("Toggle Drawing       ⌃⌥D", #selector(toggleDrawing), to: menu)
        addMenuItem("Toggle Cursor Halo   ⌃⌥H", #selector(toggleHalo), to: menu)
        addMenuItem("Toggle Spotlight     ⌃⌥L", #selector(toggleSpotlight), to: menu)
        menu.addItem(.separator())
        let toolMenu = NSMenu(title: "Drawing Tool")
        for tool in DrawingTool.allCases {
            let item = NSMenuItem(title: tool.rawValue, action: #selector(changeTool(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tool.rawValue
            toolMenu.addItem(item)
        }
        let tools = NSMenuItem(title: "Drawing Tool", action: nil, keyEquivalent: "")
        tools.submenu = toolMenu
        menu.addItem(tools)

        let colorMenu = NSMenu(title: "Ink Color")
        for (label, value) in [("Red", "red"), ("Yellow", "yellow"),
                               ("Green", "green"), ("Blue", "blue"), ("White", "white")] {
            let item = NSMenuItem(title: label, action: #selector(changeColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            colorMenu.addItem(item)
        }
        let colors = NSMenuItem(title: "Ink Color", action: nil, keyEquivalent: "")
        colors.submenu = colorMenu
        menu.addItem(colors)
        menu.addItem(.separator())
        addMenuItem("Undo Last Stroke    ⌃⌥Z", #selector(undo), to: menu)
        addMenuItem("Clear All Screens   ⌃⌥K", #selector(clearAll), to: menu)
        menu.addItem(.separator())
        addMenuItem("Quit LocalInk", #selector(quit), to: menu)
        statusItem.menu = menu
    }

    private func addMenuItem(_ title: String, _ action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func toggleDrawing() {
        drawingEnabled.toggle()
        for (window, overlay) in zip(windows, overlays) {
            window.ignoresMouseEvents = !drawingEnabled
            overlay.drawingEnabled = drawingEnabled
            overlay.needsDisplay = true
        }
        statusItem.button?.image = NSImage(
            systemSymbolName: drawingEnabled ? "pencil.circle.fill" : "pencil.tip.crop.circle",
            accessibilityDescription: "LocalInk")
    }

    @objc private func toggleHalo() {
        showHalo.toggle()
        for overlay in overlays { overlay.showHalo = showHalo; overlay.needsDisplay = true }
    }

    @objc private func toggleSpotlight() {
        showSpotlight.toggle()
        for overlay in overlays { overlay.showSpotlight = showSpotlight; overlay.needsDisplay = true }
    }

    @objc private func changeTool(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let tool = DrawingTool(rawValue: raw) else { return }
        selectedTool = tool
        for overlay in overlays { overlay.tool = tool }
    }

    @objc private func changeColor(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        switch name {
        case "yellow": selectedColor = .systemYellow
        case "green": selectedColor = .systemGreen
        case "blue": selectedColor = .systemBlue
        case "white": selectedColor = .white
        default: selectedColor = .systemRed
        }
        for overlay in overlays { overlay.inkColor = selectedColor }
    }

    @objc private func undo() { (lastEdited ?? overlays.first)?.undo() }
    @objc private func clearAll() { overlays.forEach { $0.clear() } }
    @objc private func quit() { NSApp.terminate(nil) }

    // Carbon hotkeys do not require listening to every key you type.
    // CTRL+OPTION+D/H/L/Z/K are system-wide.
    private func installHotkeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }
            var hotkey = EventHotKeyID()
            let result = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size,
                                           nil, &hotkey)
            guard result == noErr else { return result }
            let controller = Unmanaged<OverlayController>.fromOpaque(userData).takeUnretainedValue()
            switch hotkey.id {
            case 1: controller.toggleDrawing()
            case 2: controller.toggleHalo()
            case 3: controller.toggleSpotlight()
            case 4: controller.undo()
            case 5: controller.clearAll()
            default: break
            }
            return noErr
        }
        let observer = Unmanaged.passUnretained(self).toOpaque()
        let installResult = InstallEventHandler(GetApplicationEventTarget(), callback,
                                                1, &eventType, observer, &hotKeyHandler)
        guard installResult == noErr else { return }
        let hotkeys: [(UInt32, Int)] = [(1, kVK_ANSI_D), (2, kVK_ANSI_H),
                                       (3, kVK_ANSI_L), (4, kVK_ANSI_Z),
                                       (5, kVK_ANSI_K)]
        for (id, key) in hotkeys {
            var identifier = EventHotKeyID()
            identifier.signature = OSType(0x4C494E4B) // 'LINK'
            identifier.id = id
            var ref: EventHotKeyRef?
            let result = RegisterEventHotKey(UInt32(key), UInt32(controlKey | optionKey),
                                              identifier, GetApplicationEventTarget(), 0, &ref)
            if result == noErr, let ref = ref { hotKeyRefs.append(ref) }
        }
    }
}

let app = NSApplication.shared
let controller = OverlayController()
app.delegate = controller
app.run()
