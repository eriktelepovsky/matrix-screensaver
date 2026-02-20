import ScreenSaver
import AppKit

@objc(MatrixScreenSaverView)
final class MatrixScreenSaverView: ScreenSaverView {

    private let colSize:     CGFloat = 14
    private let fadeAlpha:   CGFloat = 0.04
    private let speedMin:    Double  = 0.5
    private let speedMax:    Double  = 2.0
    private let resetChance: Double  = 0.3

    private let trailColor = NSColor(calibratedHue: 120/360, saturation: 1.0, brightness: 0.65, alpha: 1)
    private let headColor  = NSColor(calibratedHue: 120/360, saturation: 0.1, brightness: 1.0,  alpha: 1)
    private let glyphs     = Array("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789")

    private var numCols:   Int = 0
    private var numRows:   Int = 0
    private var drops:     [Double] = []
    private var speeds:    [Double] = []
    private var prevHeads: [Int] = []
    private var grid:      [[Character?]] = []
    private var accumRep:  NSBitmapImageRep?
    private var repW: Int = 0
    private var repH: Int = 0

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 20.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 20.0
    }

    private func setup() {
        repW    = max(1, Int(bounds.width))
        repH    = max(1, Int(bounds.height))
        numCols = repW / Int(colSize)
        numRows = repH / Int(colSize) + 2
        guard numCols > 0 else { return }

        drops     = (0..<numCols).map { _ in Double.random(in: -Double(numRows)...0) }
        speeds    = (0..<numCols).map { _ in Double.random(in: speedMin...speedMax) }
        prevHeads = Array(repeating: -1, count: numCols)
        grid      = Array(repeating: Array(repeating: nil, count: numRows), count: numCols)

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: repW, pixelsHigh: repH,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = ctx
            NSColor.black.setFill()
            NSRect(x: 0, y: 0, width: repW, height: repH).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
        accumRep = rep
    }

    override func animateOneFrame() {
        if numCols == 0 { setup() }
        guard let rep = accumRep, numCols > 0 else { return }
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx

        // Fade all existing content toward black
        NSColor.black.withAlphaComponent(fadeAlpha).setFill()
        NSRect(x: 0, y: 0, width: CGFloat(repW), height: CGFloat(repH)).fill()

        let font       = NSFont.monospacedSystemFont(ofSize: colSize, weight: .regular)
        let trailAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: trailColor]
        let headAttrs:  [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: headColor]

        for i in 0..<numCols {
            let head = Int(drops[i])
            let x    = CGFloat(i) * colSize

            // Draw new trail chars since last frame
            let start = max(0, prevHeads[i])
            for r in start..<max(start, head) {
                guard r < numRows else { break }
                if grid[i][r] == nil { grid[i][r] = glyphs.randomElement() }
                let y = CGFloat(repH) - CGFloat(r + 1) * colSize
                guard y > -colSize else { continue }
                NSAttributedString(string: String(grid[i][r]!), attributes: trailAttrs)
                    .draw(at: NSPoint(x: x, y: y))
            }

            // Draw head char (brighter)
            if head >= 0 && head < numRows {
                if grid[i][head] == nil { grid[i][head] = glyphs.randomElement() }
                let y = CGFloat(repH) - CGFloat(head + 1) * colSize
                if y > -colSize {
                    NSAttributedString(string: String(grid[i][head]!), attributes: headAttrs)
                        .draw(at: NSPoint(x: x, y: y))
                }
            }

            prevHeads[i] = head
            drops[i]    += speeds[i]

            if Int(drops[i]) >= numRows, Double.random(in: 0...1) < resetChance {
                drops[i]     = 0
                prevHeads[i] = -1
                grid[i]      = Array(repeating: nil, count: numRows)
            }
        }

        NSGraphicsContext.restoreGraphicsState()
        setNeedsDisplay(bounds)
        display()
    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()
        accumRep?.draw(in: bounds)
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
