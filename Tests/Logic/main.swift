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

// Composite orientation: a white screenshot plus a red diagonal stroke must
// place the stroke center at the expected pixel in top-left output coordinates.
func makeWhiteImage() -> CGImage {
    let shot = CGContext(data: nil, width: 200, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                         space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    shot.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    shot.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
    return shot.makeImage()!
}

func pixel(_ image: CGImage, x: Int, y: Int) -> (UInt8, UInt8, UInt8) {
    let provider = image.dataProvider!
    let data = CFDataGetBytePtr(provider.data)!
    let bpp = image.bitsPerPixel / 8
    let offset = y * image.bytesPerRow + x * bpp
    return (data[offset], data[offset + 1], data[offset + 2])
}

let diag = Annotation(tool: .pen, points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)],
                      color: InkColor(red: 1, green: 0, blue: 0), thickness: 20)
let composite = ExportService.renderAnnotatedImage(screenshot: makeWhiteImage(),
                                                   annotations: [diag], scale: 2)
let center = pixel(composite, x: 100, y: 100)
check(center.0 > 150 && center.1 < 100 && center.2 < 100, "composite places stroke center correctly (red at display center)")
let topRight = pixel(composite, x: 190, y: 9)
check(topRight.0 > 150 && topRight.1 < 100, "composite places stroke top-right endpoint correctly")
let bottomLeft = pixel(composite, x: 9, y: 190)
check(bottomLeft.0 > 150 && bottomLeft.1 < 100, "composite places stroke bottom-left endpoint correctly")

// New tools: line, redact, counter
let line = Annotation(tool: .line, points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)], color: .blue, thickness: 4)
check(line.contains(CGPoint(x: 50, y: 50)), "line contains midpoint")
check(!line.contains(CGPoint(x: 80, y: 20)), "line rejects off-axis point")

let redact = Annotation(tool: .redact, points: [CGPoint(x: 10, y: 10), CGPoint(x: 90, y: 60)], color: .black, thickness: 4)
check(redact.contains(CGPoint(x: 50, y: 35)), "redact contains interior")
check(!redact.contains(CGPoint(x: 95, y: 90)), "redact rejects outside point")

let counter = Annotation(tool: .counter, points: [CGPoint(x: 50, y: 50)], color: .red, thickness: 4, text: "3", fontSize: 24)
check(counter.contains(CGPoint(x: 50, y: 50)), "counter contains center")
check(counter.boundingBox.width > 20, "counter has a sized bounding box")
check(ExportService.svgString(for: [redact, counter], displayHeight: 100).contains("<circle"), "svg contains counter circle")

let ctx2 = CGContext(data: nil, width: 200, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                     space: CGColorSpaceCreateDeviceRGB(),
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx2.scaleBy(x: 2, y: 2)
Renderer.draw([line, redact, counter], in: ctx2)
check(ctx2.makeImage() != nil, "renderer handles line, redact, and counter")

// Multiline text must use the wrapped layout, not a single CTLine.
let oneLine = Renderer.textBlockSize("Hello", fontSize: 24)
let twoLines = Renderer.textBlockSize("Hello\nWorld", fontSize: 24)
check(twoLines.height > oneLine.height, "multiline text block grows in height")

// SVG: explicit width, whiteboard background, arrow head, and highlighter width.
let bgSVG = ExportService.svgString(for: [rect, pen, line], displayWidth: 300,
                                    displayHeight: 200, background: .white)
check(bgSVG.contains("width=\"300.0\"") && bgSVG.contains("viewBox=\"0 0 300.0 200.0\""), "svg includes display size")
check(bgSVG.contains("<rect x=\"0\" y=\"0\" width=\"300.0\""), "svg includes whiteboard background")

let arrow = Annotation(tool: .arrow, points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)],
                       color: .red, thickness: 4)
let arrowSVG = ExportService.svgString(for: [arrow], displayWidth: 200, displayHeight: 200)
check(arrowSVG.contains("<polygon"), "svg draws an arrow head")

let highlighter = Annotation(tool: .highlighter, points: [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 50)],
                             color: .yellow, thickness: 4, opacity: 1)
let highlighterSVG = ExportService.svgString(for: [highlighter], displayWidth: 200, displayHeight: 200)
check(highlighterSVG.contains("stroke-width=\"10.4\""), "svg matches highlighter width")
check(highlighterSVG.contains("opacity=\"0.45\""), "svg caps highlighter opacity")

let wrapped = Annotation(tool: .text, points: [CGPoint(x: 10, y: 100)],
                         color: .black, thickness: 4,
                         text: "This is a long annotation that should wrap onto several lines when exported to SVG",
                         fontSize: 24)
let wrappedSVG = ExportService.svgString(for: [wrapped], displayWidth: 300, displayHeight: 200)
check(wrappedSVG.components(separatedBy: "<tspan").count > 2, "svg wraps long text into multiple lines")

// Whiteboard export fills the canvas instead of using the screenshot.
let whiteboard = ExportService.renderAnnotatedImage(screenshot: makeWhiteImage(),
                                                    annotations: [rect], scale: 1,
                                                    background: InkColor(red: 1, green: 1, blue: 1))
let bgPixel = pixel(whiteboard, x: 1, y: 1)
check(bgPixel.0 > 240 && bgPixel.1 > 240 && bgPixel.2 > 240, "whiteboard export uses background color")

// Select should let ordinary clicks reach the app below, while retaining
// annotation selection and an in-progress drag.
let selectionState = StateController()
selectionState.annotationMode = .drawing
selectionState.activeTool = .select
check(!selectionState.shouldCaptureMouse(overAnnotation: false, selectionGestureActive: false),
      "select passes clicks through empty space")
check(selectionState.shouldCaptureMouse(overAnnotation: true, selectionGestureActive: false),
      "select can pick an annotation")
check(selectionState.shouldCaptureMouse(overAnnotation: false, selectionGestureActive: true),
      "select keeps a drag after leaving the annotation")
selectionState.passThroughHeld = true
check(!selectionState.shouldCaptureMouse(overAnnotation: true, selectionGestureActive: true),
      "Command click-through overrides selection")
selectionState.passThroughHeld = false
selectionState.activeTool = .pen
check(selectionState.shouldCaptureMouse(overAnnotation: false, selectionGestureActive: false),
      "drawing tools still capture empty space")
selectionState.activeTool = .select
selectionState.whiteboardEnabled = true
check(selectionState.shouldCaptureMouse(overAnnotation: false, selectionGestureActive: false),
      "whiteboard still captures input in select mode")

print(failures == 0 ? "ALL TESTS PASSED" : "\(failures) TEST(S) FAILED")
exit(failures == 0 ? 0 : 1)
