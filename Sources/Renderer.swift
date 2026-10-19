import AppKit
import CoreText

// MARK: - Renderer

// Draws annotations into a CoreGraphics context. The context is expected to be
// in the overlay's logical coordinate space (origin at the display's bottom-left,
// Y up, measured in points). The same path is used for the live overlay and for
// export, so geometry always agrees. Export callers simply apply a uniform
// `scaleBy(scale, scale)` to map points to backing pixels.
enum Renderer {

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
        case .rectangle:
            drawShape(annotation, rounded: false, in: ctx)
        case .ellipse:
            drawShape(annotation, rounded: true, in: ctx)
        case .select:
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

    // MARK: Text

    private static func drawText(_ annotation: Annotation, in ctx: CGContext) {
        guard let text = annotation.text, !text.isEmpty, let origin = annotation.points.first else { return }
        let font = NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: strokeColor(for: annotation)
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: origin.x, y: origin.y)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    static func textSize(_ text: String, fontSize: CGFloat) -> CGSize {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)
        return CTLineGetBoundsWithOptions(line, []).size
    }
}
