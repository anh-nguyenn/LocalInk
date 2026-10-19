import AppKit
import ImageIO
import UniformTypeIdentifiers

// Renders a short animated GIF that demonstrates the LocalInk workflow:
// annotate over a slide, point with the halo, spotlight a detail, then clear.

let width = 720
let height = 450
let fps = 12
let duration = 6.0
let frameCount = Int(duration * Double(fps))

func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

let bgTop = c(26, 34, 51)
let bgBottom = c(12, 16, 24)
let panel = c(22, 28, 41)
let textMain = c(236, 239, 247)
let textMuted = c(132, 142, 163)
let accent = c(255, 107, 74)
let yellow = c(255, 209, 42)
let barTop = c(255, 184, 74, 0.65)
let barBottom = c(255, 107, 74, 0.18)

func rectTL(_ x: CGFloat, _ top: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: CGFloat(height) - top - h, width: w, height: h)
}

func pointTL(_ x: CGFloat, _ top: CGFloat) -> NSPoint {
    NSPoint(x: x, y: CGFloat(height) - top)
}

func smooth(_ x: Double) -> Double {
    let t = max(0, min(1, x))
    return t * t * (3 - 2 * t)
}

func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

func cursorPosition(at t: Double) -> NSPoint {
    let keys: [(Double, Double, Double)] = [
        (0.0, 706, 440),
        (0.7, 648, 300),
        (2.2, 560, 262),
        (3.0, 476, 244),
        (3.7, 322, 150),
        (4.5, 250, 122),
        (5.2, 352, 180),
        (6.0, 640, 430)
    ]
    for i in 0..<(keys.count - 1) {
        let a = keys[i], b = keys[i + 1]
        if t >= a.0 && t <= b.0 {
            let f = smooth((t - a.0) / (b.0 - a.0))
            return NSPoint(x: lerp(a.1, b.1, f), y: lerp(a.2, b.2, f))
        }
    }
    return NSPoint(x: 640, y: 430)
}

func drawText(_ string: String, _ rect: NSRect, size: CGFloat, weight: NSFont.Weight,
              color: NSColor, align: NSTextAlignment = .left, alpha: CGFloat = 1) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineHeightMultiple = 1.02
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color.withAlphaComponent(alpha),
        .paragraphStyle: paragraph
    ]
    (string as NSString).draw(in: rect, withAttributes: attributes)
}

func strokePolyline(_ points: [NSPoint], color: NSColor, width: CGFloat, alpha: CGFloat = 1) {
    guard points.count >= 2 else { return }
    let path = NSBezierPath()
    path.move(to: pointTL(points[0].x, points[0].y))
    for p in points.dropFirst() { path.line(to: pointTL(p.x, p.y)) }
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.withAlphaComponent(alpha).setStroke()
    path.stroke()
}

func cursorPath(at p: NSPoint, scale: CGFloat = 1.0) -> NSBezierPath {
    let shape: [(CGFloat, CGFloat)] = [
        (0, 0), (0, 17), (4, 13), (7, 20), (10, 19), (7, 12), (12, 12)
    ]
    let path = NSBezierPath()
    for (i, pt) in shape.enumerated() {
        let x = p.x + pt.0 * scale
        let y = p.y + pt.1 * scale
        let cgp = pointTL(x, y)
        if i == 0 { path.move(to: cgp) } else { path.line(to: cgp) }
    }
    path.close()
    return path
}

func drawBars(alpha: CGFloat) {
    let heights: [CGFloat] = [58, 92, 74, 122, 104, 150]
    let baseTop: CGFloat = 372
    for (i, h) in heights.enumerated() {
        let x = 392 + CGFloat(i) * 44
        let r = rectTL(x, baseTop - h, 30, h)
        let path = NSBezierPath(roundedRect: r, xRadius: 7, yRadius: 7)
        let gradient = NSGradient(starting: barTop.withAlphaComponent(barTop.alphaComponent * alpha),
                                  ending: barBottom.withAlphaComponent(barBottom.alphaComponent * alpha))!
        gradient.draw(in: path, angle: -90)
        c(255, 184, 74, 0.28 * alpha).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}

func drawEllipseProgress(center: NSPoint, rx: CGFloat, ry: CGFloat, progress: Double,
                         color: NSColor, alpha: CGFloat) {
    guard progress > 0 else { return }
    let steps = max(2, Int(progress * 120))
    var pts: [NSPoint] = []
    for i in 0...steps {
        let a = Double(i) / 120.0 * 2 * Double.pi
        let x = center.x + rx * CGFloat(sin(a))
        let y = center.y - ry * CGFloat(cos(a))
        pts.append(NSPoint(x: x, y: y))
    }
    strokePolyline(pts, color: color, width: 6, alpha: alpha)
}

func drawArrow(from a: NSPoint, to b: NSPoint, progress: Double, alpha: CGFloat) {
    guard progress > 0 else { return }
    let p = NSPoint(x: a.x + (b.x - a.x) * CGFloat(progress),
                    y: a.y + (b.y - a.y) * CGFloat(progress))
    strokePolyline([a, p], color: accent, width: 5, alpha: alpha)
    if progress > 0.92 {
        let angle = atan2(b.y - a.y, b.x - a.x)
        let len: CGFloat = 18
        let wing = CGFloat.pi / 6
        let path = NSBezierPath()
        path.move(to: pointTL(b.x, b.y))
        path.line(to: pointTL(b.x - len * cos(angle - wing), b.y - len * sin(angle - wing)))
        path.line(to: pointTL(b.x - len * cos(angle + wing), b.y - len * sin(angle + wing)))
        path.close()
        accent.withAlphaComponent(alpha).setFill()
        path.fill()
    }
}

func drawToolbar(alpha: CGFloat) {
    guard alpha > 0 else { return }
    let r = rectTL(28, 386, 196, 40)
    let bg = NSBezierPath(roundedRect: r, xRadius: 12, yRadius: 12)
    c(18, 22, 31, 0.92 * alpha).setFill()
    bg.fill()
    c(255, 255, 255, 0.14 * alpha).setStroke()
    bg.lineWidth = 1
    bg.stroke()
    let toolColors: [NSColor] = [accent, c(255, 184, 74), c(70, 214, 138), c(80, 150, 255), c(180, 120, 255)]
    for (i, col) in toolColors.enumerated() {
        let rect = rectTL(42 + CGFloat(i) * 30, 397, 18, 18)
        let p = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        if i == 0 {
            col.withAlphaComponent(alpha).setFill()
        } else {
            c(255, 255, 255, 0.13 * alpha).setFill()
        }
        p.fill()
    }
}

func drawFrame(_ t: Double) -> CGImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    // Background
    c(9, 11, 16).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    let slide = rectTL(0, 0, CGFloat(width), CGFloat(height))
    NSGradient(starting: bgTop, ending: bgBottom)?.draw(in: slide, angle: -90)

    // Window chrome
    panel.setFill()
    rectTL(0, 0, CGFloat(width), 38).fill()
    c(255, 255, 255, 0.07).setFill()
    rectTL(0, 38, CGFloat(width), 1).fill()
    let dotColors: [NSColor] = [c(255, 95, 87), c(254, 188, 46), c(40, 200, 64)]
    for (i, col) in dotColors.enumerated() {
        col.setFill()
        NSBezierPath(ovalIn: rectTL(18 + CGFloat(i) * 18, 15, 9, 9)).fill()
    }
    drawText("quarterly-review.key", rectTL(300, 13, 240, 16), size: 11, weight: .medium,
             color: textMuted, align: .center)

    // Slide content
    drawText("Q3 REVIEW", rectTL(40, 78, 260, 16), size: 10, weight: .bold,
             color: c(120, 132, 156), alpha: 0.9)
    drawText("Momentum,\nmeasured.", rectTL(40, 100, 330, 100), size: 36, weight: .bold,
             color: textMain)
    drawText("A clearer way to make the point.", rectTL(40, 196, 320, 20), size: 13,
             weight: .regular, color: textMuted)

    drawBars(alpha: 1)

    // Annotation timing
    let ellipseProgress = max(0, min(1, (t - 0.8) / 1.3))
    let arrowProgress = max(0, min(1, (t - 2.35) / 0.7))
    let annotAlpha: CGFloat = t > 5.35 ? CGFloat(max(0, (6.0 - t) / 0.65)) : 1

    drawEllipseProgress(center: NSPoint(x: 627, y: 296), rx: 40, ry: 90,
                        progress: ellipseProgress, color: accent, alpha: annotAlpha)
    drawArrow(from: NSPoint(x: 330, y: 306), to: NSPoint(x: 476, y: 246),
              progress: arrowProgress, alpha: annotAlpha)

    // Toolbar hint
    let toolbarAlpha: CGFloat = (t > 0.4 && t < 3.0) ? 1 : 0
    drawToolbar(alpha: toolbarAlpha)

    // Spotlight
    let spotIn = max(0, min(1, (t - 3.25) / 0.4))
    let spotOut = max(0, min(1, (5.45 - t) / 0.35))
    let spotAlpha = CGFloat(min(spotIn, spotOut)) * 0.62
    let cursor = cursorPosition(at: t)
    let haloCenter = NSPoint(x: cursor.x + 6, y: cursor.y + 8)
    if spotAlpha > 0.01 {
        let aperture = NSBezierPath(ovalIn: rectTL(haloCenter.x - 92, haloCenter.y - 92, 184, 184))
        let shade = NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height))
        shade.append(aperture)
        shade.windingRule = .evenOdd
        c(0, 0, 0, spotAlpha).setFill()
        shade.fill()
    }

    // Halo
    let haloAlpha: CGFloat = t > 0.65 ? 1 : 0
    if haloAlpha > 0 {
        let pulse = CGFloat(1 + 0.06 * sin(t * 5.0))
        let radius: CGFloat = 30 * pulse
        let ring = NSBezierPath(ovalIn: rectTL(haloCenter.x - radius, haloCenter.y - radius,
                                              radius * 2, radius * 2))
        ring.lineWidth = 4
        yellow.withAlphaComponent(0.85 * haloAlpha).setStroke()
        ring.stroke()
        let inner = NSBezierPath(ovalIn: rectTL(haloCenter.x - 4, haloCenter.y - 4, 8, 8))
        yellow.withAlphaComponent(0.95 * haloAlpha).setFill()
        inner.fill()
    }

    // Cursor
    let cursorAlpha: CGFloat = t > 0.15 ? 1 : 0
    let path = cursorPath(at: cursor, scale: 1.0)
    c(0, 0, 0, 0.55 * cursorAlpha).setFill()
    let shadow = path.copy() as! NSBezierPath
    shadow.transform(using: AffineTransform(translationByX: 1.5, byY: -1.5))
    shadow.fill()
    NSColor.white.withAlphaComponent(cursorAlpha).setFill()
    path.fill()
    c(20, 20, 25, 0.9 * cursorAlpha).setStroke()
    path.lineWidth = 1.2
    path.stroke()

    return rep.cgImage!
}

let outputPath = "website/assets/demo.gif"
try? FileManager.default.createDirectory(atPath: "website/assets", withIntermediateDirectories: true)
let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                       UTType.gif.identifier as CFString,
                                                       frameCount, nil) else {
    fatalError("Could not create GIF destination")
}
let fileProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
]
CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
let frameProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / Double(fps)]
]
for frame in 0..<frameCount {
    let t = Double(frame) / Double(fps)
    let image = drawFrame(t)
    CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
}
guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not finalize GIF")
}
print("Wrote \(outputPath) (\(frameCount) frames)")
