import AppKit
import ImageIO
import UniformTypeIdentifiers
import CoreText

// MARK: - Export service

// Composes a captured display with committed annotations and writes PNG,
// clipboard, or SVG output. Geometry agrees with the live overlay because both
// use Renderer with the same logical-point coordinates.
enum ExportService {

    enum ExportError: Error, LocalizedError {
        case noImage
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .noImage: return "No image to export."
            case .writeFailed: return "Could not write the image file."
            }
        }
    }

    // `screenshot` is a top-left-origin CGImage of the display. `annotations`
    // are in the overlay's bottom-left logical coordinates; `scale` maps points
    // to the screenshot's pixels.
    static func renderAnnotatedImage(screenshot: CGImage,
                                     annotations: [Annotation],
                                     scale: CGFloat,
                                     background: InkColor? = nil) -> CGImage {
        let pixelW = screenshot.width
        let pixelH = screenshot.height

        // 1. Draw the annotation layer in its native bottom-left space, scaled
        //    to backing pixels, into a transparent bitmap.
        guard let annCtx = CGContext(data: nil, width: pixelW, height: pixelH,
                                     bitsPerComponent: 8, bytesPerRow: 0,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return screenshot
        }
        annCtx.scaleBy(x: scale, y: scale)
        Renderer.draw(annotations, in: annCtx)
        guard let annImage = annCtx.makeImage() else { return screenshot }

        // 2. Composite the two top-left-origin images.
        guard let finalCtx = CGContext(data: nil, width: pixelW, height: pixelH,
                                       bitsPerComponent: 8, bytesPerRow: 0,
                                       space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return screenshot
        }
        let rect = CGRect(x: 0, y: 0, width: CGFloat(pixelW), height: CGFloat(pixelH))
        if let background {
            finalCtx.setFillColor(background.nsColor.cgColor)
            finalCtx.fill(rect)
        } else {
            finalCtx.draw(screenshot, in: rect)
        }
        finalCtx.draw(annImage, in: rect)
        return finalCtx.makeImage() ?? screenshot
    }

    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL,
                                                         UTType.png.identifier as CFString,
                                                         1, nil) else {
            throw ExportError.writeFailed
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw ExportError.writeFailed
        }
    }

    static func copyToClipboard(_ image: CGImage) {
        let size = NSSize(width: image.width, height: image.height)
        let nsImage = NSImage(cgImage: image, size: size)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
    }

    // MARK: SVG

    // Produces a standalone SVG whose top-left origin matches the display.
    static func svgString(for annotations: [Annotation],
                          displayWidth: CGFloat? = nil,
                          displayHeight: CGFloat,
                          background: InkColor? = nil) -> String {
        var elements: [String] = []
        elements.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")

        var root = "<svg xmlns=\"http://www.w3.org/2000/svg\""
        if let displayWidth {
            root += " width=\"\(displayWidth)\" height=\"\(displayHeight)\""
            root += " viewBox=\"0 0 \(displayWidth) \(displayHeight)\""
        } else {
            root += " height=\"\(displayHeight)\""
        }
        elements.append(root + ">")

        func flipY(_ y: CGFloat) -> CGFloat { displayHeight - y }
        func hex(_ color: InkColor) -> String {
            String(format: "#%02X%02X%02X",
                   Int(color.red * 255), Int(color.green * 255), Int(color.blue * 255))
        }
        func escape(_ text: String) -> String {
            text.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        }

        if let background {
            let width = displayWidth.map { "\($0)" } ?? "100%"
            elements.append("<rect x=\"0\" y=\"0\" width=\"\(width)\" height=\"\(displayHeight)\" fill=\"\(hex(background))\" opacity=\"\(background.alpha)\"/>")
        }

        for mark in annotations {
            let color = mark.color
            let stroke = hex(color)
            var opacity = color.alpha * mark.opacity
            if mark.tool == .highlighter {
                opacity = min(opacity, 0.45)
            }
            let lineWidth = mark.tool == .highlighter ? mark.thickness * 2.6 : mark.thickness
            switch mark.tool {
            case .pen, .highlighter:
                guard let first = mark.points.first else { continue }
                if mark.points.count == 1 {
                    elements.append("<circle cx=\"\(first.x)\" cy=\"\(flipY(first.y))\" r=\"\(lineWidth / 2)\" fill=\"\(stroke)\" opacity=\"\(opacity)\"/>")
                } else {
                    var d = "M \(first.x) \(flipY(first.y))"
                    for p in mark.points.dropFirst() { d += " L \(p.x) \(flipY(p.y))" }
                    elements.append("<path d=\"\(d)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(lineWidth)\" stroke-linecap=\"round\" stroke-linejoin=\"round\" opacity=\"\(opacity)\"/>")
                }
            case .arrow:
                guard let first = mark.points.first, let last = mark.points.last else { continue }
                let x1 = first.x, y1 = flipY(first.y)
                let x2 = last.x, y2 = flipY(last.y)
                elements.append("<line x1=\"\(x1)\" y1=\"\(y1)\" x2=\"\(x2)\" y2=\"\(y2)\" stroke=\"\(stroke)\" stroke-width=\"\(lineWidth)\" stroke-linecap=\"round\" opacity=\"\(opacity)\"/>")
                let angle = atan2(y2 - y1, x2 - x1)
                let headLength = max(mark.thickness * 4, 16)
                let wing = CGFloat.pi / 6
                let leftX = x2 - headLength * cos(angle - wing)
                let leftY = y2 - headLength * sin(angle - wing)
                let rightX = x2 - headLength * cos(angle + wing)
                let rightY = y2 - headLength * sin(angle + wing)
                elements.append("<polygon points=\"\(x2),\(y2) \(leftX),\(leftY) \(rightX),\(rightY)\" fill=\"\(stroke)\" opacity=\"\(opacity)\"/>")
            case .line:
                guard let first = mark.points.first, let last = mark.points.last else { continue }
                elements.append("<line x1=\"\(first.x)\" y1=\"\(flipY(first.y))\" x2=\"\(last.x)\" y2=\"\(flipY(last.y))\" stroke=\"\(stroke)\" stroke-width=\"\(lineWidth)\" stroke-linecap=\"round\" opacity=\"\(opacity)\"/>")
            case .rectangle:
                let r = mark.normalizedRect
                elements.append("<rect x=\"\(r.minX)\" y=\"\(flipY(r.maxY))\" width=\"\(r.width)\" height=\"\(r.height)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(lineWidth)\" opacity=\"\(opacity)\"/>")
            case .ellipse:
                let r = mark.normalizedRect
                elements.append("<ellipse cx=\"\(r.midX)\" cy=\"\(flipY(r.midY))\" rx=\"\(r.width / 2)\" ry=\"\(r.height / 2)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(lineWidth)\" opacity=\"\(opacity)\"/>")
            case .redact:
                let r = mark.normalizedRect
                elements.append("<rect x=\"\(r.minX)\" y=\"\(flipY(r.maxY))\" width=\"\(r.width)\" height=\"\(r.height)\" fill=\"\(stroke)\" opacity=\"\(opacity)\"/>")
            case .counter:
                guard let center = mark.points.first else { continue }
                let radius = mark.fontSize * 0.65
                let label = escape(mark.text ?? "")
                elements.append("<circle cx=\"\(center.x)\" cy=\"\(flipY(center.y))\" r=\"\(radius)\" fill=\"\(stroke)\" stroke=\"#FFFFFF\" stroke-width=\"\(max(1.5, radius * 0.08))\" opacity=\"\(opacity)\"/>")
                elements.append("<text x=\"\(center.x)\" y=\"\(flipY(center.y))\" fill=\"#FFFFFF\" font-size=\"\(mark.fontSize * 0.95)\" font-family=\"system-ui\" font-weight=\"bold\" text-anchor=\"middle\" dominant-baseline=\"central\" opacity=\"\(opacity)\">\(label)</text>")
            case .text:
                guard let text = mark.text, let origin = mark.points.first else { continue }
                let lines = Renderer.textLines(text, fontSize: mark.fontSize)
                let lineHeight = mark.fontSize * 1.2
                let firstBaseline = flipY(origin.y) + mark.fontSize * 0.8
                var spans = ""
                for (index, line) in lines.enumerated() {
                    let dy = index == 0 ? 0 : lineHeight
                    spans += "<tspan x=\"\(origin.x)\" dy=\"\(dy)\">\(escape(line))</tspan>"
                }
                elements.append("<text x=\"\(origin.x)\" y=\"\(firstBaseline)\" fill=\"\(stroke)\" font-size=\"\(mark.fontSize)\" font-family=\"system-ui\" opacity=\"\(opacity)\" xml:space=\"preserve\">\(spans)</text>")
            case .eraser, .select:
                continue
            }
        }

        elements.append("</svg>")
        return elements.joined(separator: "\n")
    }
}
