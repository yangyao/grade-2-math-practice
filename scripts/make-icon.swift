import AppKit

let target = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let s = CGFloat(pixels)
        let shadow = NSShadow()
        shadow.shadowColor = color(0.23, 0.30, 0.60, 0.25)
        shadow.shadowBlurRadius = s * 0.045
        shadow.shadowOffset = NSSize(width: 0, height: -s * 0.018)
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        let outer = rounded(NSRect(x: s * 0.07, y: s * 0.07, width: s * 0.86, height: s * 0.86), s * 0.20)
        NSGradient(colors: [color(0.23, 0.77, 0.91), color(0.22, 0.53, 0.89), color(0.28, 0.35, 0.77)])!.draw(in: outer, angle: -65)
        NSGraphicsContext.restoreGraphicsState()
        color(1, 1, 1, 0.85).setStroke(); outer.lineWidth = max(0.5, s * 0.005); outer.stroke()
        // Four generous glass keys keep the arithmetic silhouette clear at Dock sizes.
        for row in 0..<2 {
            for column in 0..<2 {
                let x = s * (0.16 + CGFloat(column) * 0.36)
                let y = s * (0.16 + CGFloat(1 - row) * 0.36)
                let box = NSRect(x: x, y: y, width: s * 0.32, height: s * 0.32)
                let key = rounded(box, s * 0.083)
                let accent = row == 1 && column == 1
                NSGradient(starting: accent ? color(1, 0.91, 0.65) : color(0.96, 1, 1, 0.80), ending: accent ? color(1, 0.69, 0.32) : color(0.64, 0.86, 1, 0.30))!.draw(in: key, angle: -90)
                color(1, 1, 1, 0.60).setStroke(); key.lineWidth = s * 0.003; key.stroke()
                let cx = box.midX, cy = box.midY, d = s * 0.070
                let symbol = NSBezierPath(); symbol.lineWidth = s * 0.020; symbol.lineCapStyle = .round
                func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) { symbol.move(to: NSPoint(x: x1, y: y1)); symbol.line(to: NSPoint(x: x2, y: y2)) }
                if row == 0 { line(cx - d, cy, cx + d, cy); if column == 0 { line(cx, cy - d, cx, cy + d) } }
                else if column == 0 { line(cx - d * 0.8, cy - d * 0.8, cx + d * 0.8, cy + d * 0.8); line(cx - d * 0.8, cy + d * 0.8, cx + d * 0.8, cy - d * 0.8) }
                else { line(cx - d, cy - d * 0.43, cx + d, cy - d * 0.43); line(cx - d, cy + d * 0.43, cx + d, cy + d * 0.43) }
                (accent ? color(0.55, 0.28, 0.09) : color(0.12, 0.32, 0.58)).setStroke(); symbol.stroke()
            }
        }
        image.unlockFocus()
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: target).appendingPathComponent(filename))
    }
}
