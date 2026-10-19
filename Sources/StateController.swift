import AppKit

// MARK: - State

enum AnnotationMode {
    case off
    case drawing
    case temporaryPassThrough
}

enum ZoomMode {
    case off
    case lens
    case fullscreen
}

enum CapturePermission {
    case unchecked
    case allowed
    case denied
}

// MARK: - StateController

// The single authority for which modes are active and, crucially, whether an
// overlay may currently capture mouse input. Halo, spotlight, and zoom never
// capture input; drawing does; temporary pass-through suspends it.
final class StateController {
    var annotationMode: AnnotationMode = .off
    var activeTool: DrawingTool = .pen
    var haloEnabled = false
    var spotlightEnabled = false
    var whiteboardEnabled = false
    var zoomMode: ZoomMode = .off
    var capturePermission: CapturePermission = .unchecked
    var passThroughHeld = false

    var drawingEnabled: Bool {
        annotationMode == .drawing
    }

    var shouldCaptureMouse: Bool {
        if annotationMode == .off { return false }
        if passThroughHeld { return false }
        if annotationMode == .temporaryPassThrough { return false }
        return true
    }

    var isIdle: Bool {
        annotationMode == .off && !haloEnabled && !spotlightEnabled &&
        zoomMode == .off && !whiteboardEnabled
    }
}
