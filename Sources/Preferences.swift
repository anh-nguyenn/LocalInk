import AppKit
import Carbon

// MARK: - Shortcut

enum ShortcutAction: String, CaseIterable, Codable {
    case toggleDrawing
    case toggleHalo
    case toggleSpotlight
    case undo
    case redo
    case clear
    case passThrough
    case toggleToolbar

    var displayName: String {
        switch self {
        case .toggleDrawing: return "Toggle Drawing"
        case .toggleHalo: return "Toggle Cursor Halo"
        case .toggleSpotlight: return "Toggle Spotlight"
        case .undo: return "Undo"
        case .redo: return "Redo"
        case .clear: return "Clear Drawings"
        case .passThrough: return "Temporary Pass-through"
        case .toggleToolbar: return "Show / Hide Toolbar"
        }
    }
}

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var isEnabled: Bool

    init(keyCode: UInt32, modifiers: UInt32, isEnabled: Bool = true) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyCodeDisplayName)
        return parts.joined()
    }

    private var keyCodeDisplayName: String {
        let special: [UInt32: String] = [
            UInt32(kVK_Space): "Space",
            UInt32(kVK_Return): "Return",
            UInt32(kVK_Delete): "Delete",
            UInt32(kVK_Escape): "Escape",
            UInt32(kVK_UpArrow): "Up",
            UInt32(kVK_DownArrow): "Down",
            UInt32(kVK_LeftArrow): "Left",
            UInt32(kVK_RightArrow): "Right",
            UInt32(kVK_Tab): "Tab"
        ]
        if let name = special[keyCode] { return name }
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            if let code = keyCodeForCharacter(letter), code == keyCode {
                return String(letter)
            }
        }
        for digit in "0123456789" {
            if let code = keyCodeForCharacter(digit), code == keyCode {
                return String(digit)
            }
        }
        return "Key \(keyCode)"
    }

    private func keyCodeForCharacter(_ character: Character) -> UInt32? {
        switch character {
        case "A": return UInt32(kVK_ANSI_A)
        case "B": return UInt32(kVK_ANSI_B)
        case "C": return UInt32(kVK_ANSI_C)
        case "D": return UInt32(kVK_ANSI_D)
        case "E": return UInt32(kVK_ANSI_E)
        case "F": return UInt32(kVK_ANSI_F)
        case "G": return UInt32(kVK_ANSI_G)
        case "H": return UInt32(kVK_ANSI_H)
        case "I": return UInt32(kVK_ANSI_I)
        case "J": return UInt32(kVK_ANSI_J)
        case "K": return UInt32(kVK_ANSI_K)
        case "L": return UInt32(kVK_ANSI_L)
        case "M": return UInt32(kVK_ANSI_M)
        case "N": return UInt32(kVK_ANSI_N)
        case "O": return UInt32(kVK_ANSI_O)
        case "P": return UInt32(kVK_ANSI_P)
        case "Q": return UInt32(kVK_ANSI_Q)
        case "R": return UInt32(kVK_ANSI_R)
        case "S": return UInt32(kVK_ANSI_S)
        case "T": return UInt32(kVK_ANSI_T)
        case "U": return UInt32(kVK_ANSI_U)
        case "V": return UInt32(kVK_ANSI_V)
        case "W": return UInt32(kVK_ANSI_W)
        case "X": return UInt32(kVK_ANSI_X)
        case "Y": return UInt32(kVK_ANSI_Y)
        case "Z": return UInt32(kVK_ANSI_Z)
        case "0": return UInt32(kVK_ANSI_0)
        case "1": return UInt32(kVK_ANSI_1)
        case "2": return UInt32(kVK_ANSI_2)
        case "3": return UInt32(kVK_ANSI_3)
        case "4": return UInt32(kVK_ANSI_4)
        case "5": return UInt32(kVK_ANSI_5)
        case "6": return UInt32(kVK_ANSI_6)
        case "7": return UInt32(kVK_ANSI_7)
        case "8": return UInt32(kVK_ANSI_8)
        case "9": return UInt32(kVK_ANSI_9)
        default: return nil
        }
    }
}

// MARK: - Preferences

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard
    private let shortcutKey = "LocalInk.shortcuts"
    private let colorKey = "LocalInk.inkColor"
    private let widthKey = "LocalInk.inkWidth"

    private init() {}

    // MARK: Shortcuts

    static func defaultShortcuts() -> [ShortcutAction: Shortcut] {
        [
            .toggleDrawing: Shortcut(keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(controlKey | optionKey)),
            .toggleHalo: Shortcut(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(controlKey | optionKey)),
            .toggleSpotlight: Shortcut(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(controlKey | optionKey)),
            .undo: Shortcut(keyCode: UInt32(kVK_ANSI_Z), modifiers: UInt32(controlKey | optionKey)),
            .redo: Shortcut(keyCode: UInt32(kVK_ANSI_Y), modifiers: UInt32(controlKey | optionKey)),
            .clear: Shortcut(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(controlKey | optionKey)),
            .passThrough: Shortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(controlKey | optionKey)),
            .toggleToolbar: Shortcut(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(controlKey | optionKey))
        ]
    }

    // Stored shortcuts never overwrite existing bindings on upgrade.
    var shortcuts: [ShortcutAction: Shortcut] {
        get {
            guard let data = defaults.data(forKey: shortcutKey),
                  let decoded = try? JSONDecoder().decode([String: Shortcut].self, from: data) else {
                return Preferences.defaultShortcuts()
            }
            var result: [ShortcutAction: Shortcut] = [:]
            for (key, value) in decoded {
                if let action = ShortcutAction(rawValue: key) {
                    result[action] = value
                }
            }
            for (action, shortcut) in Preferences.defaultShortcuts() where result[action] == nil {
                result[action] = shortcut
            }
            return result
        }
        set {
            var encoded: [String: Shortcut] = [:]
            for (action, shortcut) in newValue {
                encoded[action.rawValue] = shortcut
            }
            if let data = try? JSONEncoder().encode(encoded) {
                defaults.set(data, forKey: shortcutKey)
            }
        }
    }

    func resetShortcuts() {
        defaults.removeObject(forKey: shortcutKey)
    }

    // MARK: Drawing

    var inkColor: InkColor {
        get {
            guard let data = defaults.data(forKey: colorKey),
                  let decoded = try? JSONDecoder().decode(InkColor.self, from: data) else {
                return .red
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: colorKey)
            }
        }
    }

    var inkWidth: CGFloat {
        get {
            let value = defaults.double(forKey: widthKey)
            return value > 0 ? value : 4
        }
        set { defaults.set(Double(newValue), forKey: widthKey) }
    }

    var inkTool: DrawingTool {
        get {
            guard let raw = defaults.string(forKey: "LocalInk.tool"),
                  let tool = DrawingTool(rawValue: raw), tool != .select else { return .pen }
            return tool
        }
        set { defaults.set(newValue.rawValue, forKey: "LocalInk.tool") }
    }

    var inkOpacity: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.inkOpacity")
            return value > 0 ? value : 1
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.inkOpacity") }
    }

    var autoEraseDelay: TimeInterval {
        get { defaults.double(forKey: "LocalInk.autoEraseDelay") }
        set { defaults.set(Double(newValue), forKey: "LocalInk.autoEraseDelay") }
    }

    // MARK: Halo

    var haloColor: InkColor {
        get {
            guard let data = defaults.data(forKey: "LocalInk.haloColor"),
                  let decoded = try? JSONDecoder().decode(InkColor.self, from: data) else {
                return .yellow
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: "LocalInk.haloColor") }
        }
    }

    var haloSize: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.haloSize")
            return value > 0 ? value : 30
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.haloSize") }
    }

    var haloOpacity: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.haloOpacity")
            return value > 0 ? value : 0.85
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.haloOpacity") }
    }

    var haloRingOnly: Bool {
        get { defaults.object(forKey: "LocalInk.haloRingOnly") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "LocalInk.haloRingOnly") }
    }

    // MARK: Spotlight

    var spotlightSize: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.spotlightSize")
            return value > 0 ? value : 105
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.spotlightSize") }
    }

    var spotlightDimLevel: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.spotlightDim")
            return value > 0 ? value : 0.60
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.spotlightDim") }
    }

    // MARK: Whiteboard

    var whiteboardColor: InkColor {
        get {
            guard let data = defaults.data(forKey: "LocalInk.whiteboardColor"),
                  let decoded = try? JSONDecoder().decode(InkColor.self, from: data) else {
                return .white
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: "LocalInk.whiteboardColor") }
        }
    }

    // MARK: Zoom and capture

    var lensSize: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.lensSize")
            return value > 0 ? value : 200
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.lensSize") }
    }

    var zoomFactor: CGFloat {
        get {
            let value = defaults.double(forKey: "LocalInk.zoomFactor")
            return value > 0 ? value : 2.5
        }
        set { defaults.set(Double(newValue), forKey: "LocalInk.zoomFactor") }
    }

    // MARK: General

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "LocalInk.launchAtLogin") }
        set { defaults.set(newValue, forKey: "LocalInk.launchAtLogin") }
    }

    var showDockIcon: Bool {
        get { defaults.bool(forKey: "LocalInk.showDockIcon") }
        set { defaults.set(newValue, forKey: "LocalInk.showDockIcon") }
    }

    var showControlWindow: Bool {
        get { defaults.object(forKey: "LocalInk.showControlWindow") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "LocalInk.showControlWindow") }
    }

    var sessionRetention: String {
        get { defaults.string(forKey: "LocalInk.sessionRetention") ?? "untilQuit" }
        set { defaults.set(newValue, forKey: "LocalInk.sessionRetention") }
    }

    var exportFolder: String? {
        get { defaults.string(forKey: "LocalInk.exportFolder") }
        set { defaults.set(newValue, forKey: "LocalInk.exportFolder") }
    }
}
