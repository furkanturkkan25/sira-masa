import AppKit

let canvas: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas), flipped: true) { _ in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
    ctx.scaleBy(x: canvas / 64, y: canvas / 64)
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
        NSColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: 1).cgColor
    }

    ctx.setFillColor(rgb(88, 167, 0))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 6, y: 10, width: 52, height: 50), cornerWidth: 18, cornerHeight: 18, transform: nil))
    ctx.fillPath()

    ctx.setFillColor(rgb(88, 204, 2))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 6, y: 4, width: 52, height: 50), cornerWidth: 18, cornerHeight: 18, transform: nil))
    ctx.fillPath()

    ctx.setFillColor(rgb(255, 255, 255))
    ctx.fillEllipse(in: CGRect(x: 16, y: 12, width: 32, height: 32))

    ctx.setFillColor(rgb(60, 60, 60))
    ctx.fillEllipse(in: CGRect(x: 22.8, y: 21.9, width: 6.4, height: 8.2))
    ctx.fillEllipse(in: CGRect(x: 34.8, y: 21.9, width: 6.4, height: 8.2))

    ctx.setFillColor(rgb(255, 255, 255))
    ctx.fillEllipse(in: CGRect(x: 25.95, y: 23.45, width: 2.3, height: 2.3))
    ctx.fillEllipse(in: CGRect(x: 37.95, y: 23.45, width: 2.3, height: 2.3))

    ctx.setStrokeColor(rgb(60, 60, 60))
    ctx.setLineWidth(2.4)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: 25, y: 33.5))
    ctx.addCurve(to: CGPoint(x: 39, y: 33.5), control1: CGPoint(x: 27.2, y: 36.7), control2: CGPoint(x: 36.8, y: 36.7))
    ctx.strokePath()

    ctx.setFillColor(rgb(255, 150, 0))
    ctx.move(to: CGPoint(x: 46, y: 12.5))
    ctx.addCurve(to: CGPoint(x: 48.2, y: 18.7), control1: CGPoint(x: 48.4, y: 13.7), control2: CGPoint(x: 49.2, y: 16.1))
    ctx.addCurve(to: CGPoint(x: 43, y: 18.3), control1: CGPoint(x: 46.6, y: 17.3), control2: CGPoint(x: 44.8, y: 17.1))
    ctx.addCurve(to: CGPoint(x: 46, y: 12.5), control1: CGPoint(x: 44.7, y: 15.9), control2: CGPoint(x: 45, y: 14.1))
    ctx.closePath()
    ctx.fillPath()
    return true
}

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("png yok\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
