import AppKit

// Generates Resources/AppIcon.icns from code so the release has a consistent,
// original identity. Run with scripts/make-icon.sh.

let outputDir = "Resources/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func drawIcon(pixels: Int) -> NSImage {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    ctx.setShouldAntialias(true)

    // Rounded background with a deep ink gradient.
    let inset = size * 0.06
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = size * 0.22
    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let colors = [
        NSColor(srgbRed: 0.11, green: 0.13, blue: 0.20, alpha: 1).cgColor,
        NSColor(srgbRed: 0.05, green: 0.06, blue: 0.10, alpha: 1).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
        ctx.saveGState()
        background.addClip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: size),
                               end: CGPoint(x: size, y: 0),
                               options: [])
        ctx.restoreGState()
    }

    // Ink swoosh.
    let swoosh = NSBezierPath()
    swoosh.move(to: CGPoint(x: size * 0.26, y: size * 0.30))
    swoosh.curve(to: CGPoint(x: size * 0.72, y: size * 0.70),
                 controlPoint1: CGPoint(x: size * 0.30, y: size * 0.68),
                 controlPoint2: CGPoint(x: size * 0.60, y: size * 0.34))
    swoosh.lineWidth = size * 0.075
    swoosh.lineCapStyle = .round
    NSColor(srgbRed: 1.0, green: 0.42, blue: 0.30, alpha: 1).setStroke()
    swoosh.stroke()

    // Arrow tip.
    let tip = CGPoint(x: size * 0.72, y: size * 0.70)
    let head = NSBezierPath()
    head.move(to: tip)
    head.line(to: CGPoint(x: tip.x - size * 0.15, y: tip.y - size * 0.02))
    head.line(to: CGPoint(x: tip.x - size * 0.03, y: tip.y - size * 0.16))
    head.close()
    NSColor(srgbRed: 1.0, green: 0.42, blue: 0.30, alpha: 1).setFill()
    head.fill()

    // Highlight ring.
    let ringRect = CGRect(x: size * 0.17, y: size * 0.17, width: size * 0.30, height: size * 0.30)
    let ring = NSBezierPath(ovalIn: ringRect)
    ring.lineWidth = size * 0.032
    NSColor(srgbRed: 1.0, green: 0.82, blue: 0.16, alpha: 1).setStroke()
    ring.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, pixels: Int, name: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: "\(outputDir)/\(name)"))
    }
}

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")
]

for (pixels, name) in variants {
    writePNG(drawIcon(pixels: pixels), pixels: pixels, name: name)
}
print("Wrote \(variants.count) icon images to \(outputDir)")
