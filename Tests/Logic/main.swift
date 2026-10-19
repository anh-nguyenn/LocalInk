import AppKit
import CoreGraphics

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if cond { print("PASS: \(msg)") } else { print("FAIL: \(msg)"); failures += 1 }
}

// Geometry: negative-direction rectangle
let rect = Annotation(tool: .rectangle, points: [CGPoint(x: 100, y: 100), CGPoint(x: 10, y: 10)], color: .red, thickness: 4)
let nr = rect.normalizedRect
check(abs(nr.minX - 10) < 0.001 && abs(nr.minY - 10) < 0.001 && abs(nr.width - 90) < 0.001 && abs(nr.height - 90) < 0.001, "negative-direction rectangle normalized")

// Ellipse contains center
let ell = Annotation(tool: .ellipse, points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)], color: .blue, thickness: 4)
check(ell.contains(CGPoint(x: 50, y: 50)), "ellipse contains center")

// Pen stroke hit-test
let pen = Annotation(tool: .pen, points: [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 50, y: 50)], color: .green, thickness: 4)
check(pen.contains(CGPoint(x: 50, y: 25)), "pen contains point on stroke")
check(!pen.contains(CGPoint(x: 100, y: 100)), "pen rejects far point")

// SVG export
let svg = ExportService.svgString(for: [rect, pen], displayHeight: 200)
check(svg.contains("<rect"), "svg contains rect element")
check(svg.contains("<path"), "svg contains pen path")
check(svg.contains("</svg>"), "svg closes properly")

// Renderer produces an image without crashing
let ctx = CGContext(data: nil, width: 200, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.scaleBy(x: 2, y: 2)
Renderer.draw([rect, pen, ell], in: ctx)
let img = ctx.makeImage()
check(img != nil, "renderer produces an image")
check(img?.width == 200 && img?.height == 200, "rendered image has expected pixel size")

// Text size helper
let ts = Renderer.textSize("Hello", fontSize: 24)
check(ts.width > 0 && ts.height > 0, "text size is positive")

print(failures == 0 ? "ALL TESTS PASSED" : "\(failures) TEST(S) FAILED")
exit(failures == 0 ? 0 : 1)
