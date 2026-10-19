import AppKit
import CoreText

// MARK: - Renderer

// Draws annotations into a CoreGraphics context. The context is expected to be
// in the overlay's logical coordinate space (origin at the display's bottom-left,
// Y up, measured in points). The same path is used for the live overlay and for
// export, so geometry always agrees. Export callers simply apply a uniform
// `scaleBy(scale, scale)` to map points to backing pixels.
enum Renderer {

    // Matching width used by the live text editor.
    static let textWrapWidth: CGFloat = 220

    static func draw(_ annotations: [Annotation], in ctx: CGContext) {
        for annotation in annotations {
            draw(annotation, in: ctx)
        }
    }

    static func draw(_ annotation: Annotation, in ctx: CGContext) {
        switch annotation.tool {
        case .text:
            drawText(annotation, in: ctx)
        case .pen, .highlighter:
            drawStroke(annotation, in: ctx)
        case .arrow:
            drawArrow(annotation, in: ctx)
        case .line:
            drawLine(annotation, in: ctx)
        case .rectangle:
            drawShape(annotation, rounded: false, in: ctx)
        case .ellipse:
            drawShape(annotation, rounded: true, in: ctx)
        case .redact:
            drawRedact(annotation, in: ctx)
        case .counter:
            drawCounter(annotation, in: ctx)
        case .eraser, .select:
            break
        }
    }

    static func strokeColor(for annotation: Annotation) -> NSColor {
        var alpha = annotation.color.alpha * annotation.opacity
        if annotation.tool == .highlighter {
            alpha = min(alpha, 0.45)
        }
        return annotation.color.withAlpha(alpha).nsColor
    }

    static func lineWidth(for annotation: Annotation) -> CGFloat {
        switch annotation.tool {
        case .highlighter: return annotation.thickness * 2.6
        default: return annotation.thickness
        }
    }

    // MARK: Pen / highlighter

    private static func drawStroke(_ annotation: Annotation, in ctx: CGContext) {
        guard let first = annotation.points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        for point in annotation.points.dropFirst() {
            path.addLine(to: point)
        }
        if annotation.points.count == 1 {
            path.addLine(to: CGPoint(x: first.x + 0.01, y: first.y + 0.01))
        }
        ctx.saveGState()
        ctx.setLineWidth(lineWidth(for: annotation))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(strokeColor(for: annotation).cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Arrow

    private static func drawArrow(_ annotation: Annotation, in ctx: CGContext) {
        guard let first = annotation.points.first,
              let last = annotation.points.last else { return }
        let color = strokeColor(for: annotation)
        let width = lineWidth(for: annotation)
        let path = CGMutablePath()
        path.move(to: first)
        path.addLine(to: last)
        ctx.saveGState()
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(color.cgColor)
        ctx.addPath(path)
        ctx.strokePath()

        let angle = atan2(last.y - first.y, last.x - first.x)
        let headLength = max(width * 4.0, 16.0)
        let wing = CGFloat.pi / 6
        let tip = last
        let left = CGPoint(x: tip.x - headLength * cos(angle - wing),
                           y: tip.y - headLength * sin(angle - wing))
        let right = CGPoint(x: tip.x - headLength * cos(angle + wing),
                            y: tip.y - headLength * sin(angle + wing))
        let head = CGMutablePath()
        head.move(to: tip)
        head.addLine(to: left)
        head.addLine(to: right)
        head.closeSubpath()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(head)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: Line

    private static func drawLine(_ annotation: Annotation, in ctx: CGContext) {
        guard let first = annotation.points.first, let last = annotation.points.last else { return }
        let path = CGMutablePath()
        path.move(to: first)
        path.addLine(to: last)
        ctx.saveGState()
        ctx.setLineWidth(lineWidth(for: annotation))
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(strokeColor(for: annotation).cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Rectangle / ellipse

    private static func drawShape(_ annotation: Annotation, rounded: Bool, in ctx: CGContext) {
        guard annotation.points.count >= 2 else { return }
        let rect = annotation.normalizedRect
        guard rect.width > 0.001, rect.height > 0.001 else { return }
        let path = CGMutablePath()
        if rounded { path.addEllipse(in: rect) } else { path.addRect(rect) }
        ctx.saveGState()
        ctx.setLineWidth(lineWidth(for: annotation))
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(strokeColor(for: annotation).cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Redact / counter

    private static func drawRedact(_ annotation: Annotation, in ctx: CGContext) {
        guard annotation.points.count >= 2 else { return }
        let rect = annotation.normalizedRect
        guard rect.width > 0.5, rect.height > 0.5 else { return }
        ctx.saveGState()
        ctx.setFillColor(annotation.color.withAlpha(annotation.opacity).nsColor.cgColor)
        ctx.fill(rect)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(rect)
        ctx.restoreGState()
    }

    private static func drawCounter(_ annotation: Annotation, in ctx: CGContext) {
        guard let center = annotation.points.first else { return }
        let radius = annotation.fontSize * 0.65
        let circle = CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                              width: radius * 2, height: radius * 2),
                            transform: nil)
        ctx.saveGState()
        ctx.setFillColor(annotation.color.nsColor.cgColor)
        ctx.addPath(circle)
        ctx.fillPath()
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        ctx.setLineWidth(max(1.5, radius * 0.08))
        ctx.addPath(circle)
        ctx.strokePath()

        let text = annotation.text ?? ""
        if !text.isEmpty {
            let font = NSFont.systemFont(ofSize: annotation.fontSize * 0.95, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let attributed = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)
            let bounds = CTLineGetBoundsWithOptions(line, [])
            ctx.textMatrix = .identity
            ctx.textPosition = CGPoint(x: center.x - bounds.width / 2 - bounds.origin.x,
                                       y: center.y - bounds.height / 2 - bounds.origin.y)
            CTLineDraw(line, ctx)
        }
        ctx.restoreGState()
    }

    // MARK: Text

    private static func drawText(_ annotation: Annotation, in ctx: CGContext) {
        guard let text = annotation.text, !text.isEmpty, let origin = annotation.points.first else { return }
        let size = textBlockSize(text, fontSize: annotation.fontSize)
        guard size.height > 0 else { return }
        let framesetter = framesetter(for: text, fontSize: annotation.fontSize,
                                      color: strokeColor(for: annotation))
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: textWrapWidth, height: size.height),
                          transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(), path, nil)
        ctx.saveGState()
        ctx.textMatrix = .identity
        // Text annotations are positioned by their top-left corner so the
        // committed result matches where the editor was shown.
        ctx.translateBy(x: origin.x, y: origin.y - size.height)
        CTFrameDraw(frame, ctx)
        ctx.restoreGState()
    }

    static func textSize(_ text: String, fontSize: CGFloat) -> CGSize {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)
        return CTLineGetBoundsWithOptions(line, []).size
    }

    static func textBlockSize(_ text: String, fontSize: CGFloat,
                              wrapWidth: CGFloat = textWrapWidth) -> CGSize {
        guard !text.isEmpty else { return .zero }
        let framesetter = framesetter(for: text, fontSize: fontSize, color: .black)
        var fitRange = CFRange()
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRange(), nil,
            CGSize(width: max(1, wrapWidth), height: .greatestFiniteMagnitude),
            &fitRange)
        return CGSize(width: max(1, ceil(size.width)), height: max(1, ceil(size.height)))
    }

    // Returns the line strings produced by the same CoreText layout used for
    // drawing, so SVG exports wrap text identically.
    static func textLines(_ text: String, fontSize: CGFloat,
                          wrapWidth: CGFloat = textWrapWidth) -> [String] {
        guard !text.isEmpty else { return [] }
        let size = textBlockSize(text, fontSize: fontSize, wrapWidth: wrapWidth)
        guard size.height > 0 else { return [] }
        let framesetter = framesetter(for: text, fontSize: fontSize, color: .black)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: max(1, wrapWidth), height: size.height),
                          transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(), path, nil)
        let lines = CTFrameGetLines(frame) as? [CTLine] ?? []
        let source = text as NSString
        return lines.map { line in
            let range = CTLineGetStringRange(line)
            guard range.length > 0, range.location >= 0,
                  range.location + range.length <= source.length else { return "" }
            return source.substring(with: NSRange(location: range.location, length: range.length))
                .trimmingCharacters(in: .newlines)
        }
    }

    private static func framesetter(for text: String, fontSize: CGFloat,
                                    color: NSColor) -> CTFramesetter {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        return CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
    }
}
