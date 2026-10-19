import AppKit
import Carbon

// MARK: - HotkeyManager

// Registers system-wide Carbon hotkeys for the configured shortcut map and
// reports back through `onAction`. Only the named combinations are registered;
// no broad keyboard monitoring is installed.
final class HotkeyManager {
    var onAction: ((ShortcutAction) -> Void)?
    var onConflict: ((ShortcutAction) -> Void)?

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actionByID: [UInt32: ShortcutAction] = [:]
    private var conflicts: Set<ShortcutAction> = []

    private static let signature: OSType = 0x4C494E4B // 'LINK'

    func install() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else {
                return OSStatus(eventNotHandledErr)
            }
            var hotKeyID = EventHotKeyID()
            let result = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size,
                                           nil, &hotKeyID)
            guard result == noErr else { return result }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            if let action = manager.actionByID[hotKeyID.id] {
                manager.onAction?(action)
            }
            return noErr
        }
        let observer = Unmanaged.passUnretained(self).toOpaque()
        let installResult = InstallEventHandler(GetApplicationEventTarget(), callback,
                                                1, &eventType, observer, &handlerRef)
        guard installResult == noErr else { return }

        conflicts.removeAll()
        actionByID.removeAll()
        var nextID: UInt32 = 1
        for (action, shortcut) in Preferences.shared.shortcuts {
            guard shortcut.isEnabled else { continue }
            var identifier = EventHotKeyID()
            identifier.signature = HotkeyManager.signature
            identifier.id = nextID
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers,
                                             identifier, GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref = ref {
                hotKeyRefs[nextID] = ref
                actionByID[nextID] = action
                nextID += 1
            } else if status == eventHotKeyExistsErr {
                conflicts.insert(action)
                onConflict?(action)
            }
        }
    }

    func uninstall() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actionByID.removeAll()
        if let handler = handlerRef {
            RemoveEventHandler(handler)
            handlerRef = nil
        }
    }

    func reload() {
        uninstall()
        install()
    }

    func hasConflict(_ action: ShortcutAction) -> Bool {
        conflicts.contains(action)
    }

    var hasConflicts: Bool { !conflicts.isEmpty }

    var conflictingActions: [ShortcutAction] { Array(conflicts) }
}
