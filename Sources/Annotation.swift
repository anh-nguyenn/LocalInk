import AppKit
import CoreGraphics

// MARK: - Tool

enum DrawingTool: String, CaseIterable, Codable {
    case pen
    case arrow
    case rectangle
    case ellipse
    case text
    case highlighter
    case select

    var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .text: return "Text"
        case .highlighter: return "Highlighter"
        case .select: return "Select"
        }
    }

    var systemSymbol: String {
        switch self {
        case .pen: return "pencil.tip"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "text.cursor"
        case .highlighter: return "highlighter"
        case .select: return "cursorarrow.motionlines"
        }
    }

    var isMarkTool: Bool { self != .select }
}

// MARK: - Color

struct InkColor: Equatable, Hashable, Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var nsColor: NSColor {
        NSColor(srgbRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: NSColor) {
        let c = color.usingColorSpace(.sRGB) ?? color
        self.red = Double(c.redComponent)
        self.green = Double(c.greenComponent)
        self.blue = Double(c.blueComponent)
        self.alpha = Double(c.alphaComponent)
    }

    func withAlpha(_ a: Double) -> InkColor {
        InkColor(red: red, green: green, blue: blue, alpha: a)
    }
}

extension InkColor {
    static let red = InkColor(red: 0.96, green: 0.26, blue: 0.21)
    static let orange = InkColor(red: 1.0, green: 0.58, blue: 0.0)
    static let yellow = InkColor(red: 1.0, green: 0.85, blue: 0.1)
    static let green = InkColor(red: 0.2, green: 0.78, blue: 0.35)
    static let blue = InkColor(red: 0.13, green: 0.59, blue: 0.95)
    static let purple = InkColor(red: 0.61, green: 0.35, blue: 0.95)
    static let white = InkColor(red: 1, green: 1, blue: 1)
    static let black = InkColor(red: 0.1, green: 0.1, blue: 0.1)

    static let palette: [InkColor] = [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]
    static let paletteNames: [String] = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "White", "Black"]
}

// MARK: - Annotation

struct Annotation: Identifiable, Codable, Equatable {
    let id: UUID
    var tool: DrawingTool
    var points: [CGPoint]
    var color: InkColor
    var thickness: CGFloat
    var opacity: CGFloat
    var text: String?
    var fontSize: CGFloat
    var createdAt: Date
    var expiry: TimeInterval?

    init(id: UUID = UUID(),
         tool: DrawingTool,
         points: [CGPoint],
         color: InkColor,
         thickness: CGFloat,
         opacity: CGFloat = 1,
         text: String? = nil,
         fontSize: CGFloat = 24,
         createdAt: Date = Date(),
         expiry: TimeInterval? = nil) {
        self.id = id
        self.tool = tool
        self.points = points
        self.color = color
        self.thickness = thickness
        self.opacity = opacity
        self.text = text
        self.fontSize = fontSize
        self.createdAt = createdAt
        self.expiry = expiry
    }

    var boundingBox: CGRect {
        if tool == .text, let text {
            let size = (text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)])
            return CGRect(origin: points.first ?? .zero, size: size)
        }
        guard let first = points.first else { return .zero }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for p in points {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        let pad = thickness / 2 + 6
        return CGRect(x: minX - pad, y: minY - pad,
                      width: maxX - minX + pad * 2, height: maxY - minY + pad * 2)
    }

    func contains(_ point: CGPoint, slop: CGFloat = 6) -> Bool {
        let box = boundingBox
        guard box.insetBy(dx: -slop, dy: -slop).contains(point) else { return false }
        switch tool {
        case .pen, .highlighter:
            return distanceToPolyline(point) <= thickness / 2 + slop
        case .arrow:
            return distanceToSegment(point) <= thickness / 2 + slop
        case .rectangle:
            return normalizedRect.insetBy(dx: -slop, dy: -slop).contains(point)
        case .ellipse:
            let r = normalizedRect
            guard r.width > 0, r.height > 0 else { return false }
            let dx = (point.x - r.midX) / (r.width / 2)
            let dy = (point.y - r.midY) / (r.height / 2)
            let d = dx * dx + dy * dy
            let slopFrac = slop / max(min(r.width, r.height) / 2, 1)
            return d <= 1.0 + slopFrac
        case .text:
            return boundingBox.insetBy(dx: -slop, dy: -slop).contains(point)
        case .select:
            return false
        }
    }

    var normalizedRect: CGRect {
        guard points.count >= 2 else { return .zero }
        let a = points[0], b = points[1]
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                      width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    func translated(by delta: CGPoint) -> Annotation {
        var copy = self
        copy.points = points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
        return copy
    }

    private func distanceToPolyline(_ point: CGPoint) -> CGFloat {
        guard points.count >= 2 else { return 0 }
        var best = CGFloat.greatestFiniteMagnitude
        for i in 0..<(points.count - 1) {
            best = min(best, distance(point, toSegment: points[i], points[i + 1]))
        }
        return best
    }

    private func distanceToSegment(_ point: CGPoint) -> CGFloat {
        guard points.count >= 2 else { return 0 }
        return distance(point, toSegment: points[0], points[1])
    }

    private func distance(_ p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: p.x - a.x, y: p.y - a.y)
        let lengthSq = ab.x * ab.x + ab.y * ab.y
        guard lengthSq > 0.0001 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / lengthSq))
        let closest = CGPoint(x: a.x + ab.x * t, y: a.y + ab.y * t)
        return hypot(p.x - closest.x, p.y - closest.y)
    }
}

// MARK: - Display identity

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        if let number = deviceDescription[key] as? NSNumber {
            return CGDirectDisplayID(number.uint32Value)
        }
        return 0
    }
}
