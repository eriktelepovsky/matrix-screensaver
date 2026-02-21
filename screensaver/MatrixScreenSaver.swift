import ScreenSaver
import AppKit

@objc(MatrixScreenSaverView)
final class MatrixScreenSaverView: ScreenSaverView {

    // MARK: - Defaults keys
    private static let moduleID     = "sk.telepovsky.MatrixSaver"
    private static let kColSize     = "colSize"
    private static let kSpeed       = "speed"
    private static let kTrailLen    = "trailLen"
    private static let kTrailRed    = "trailR"
    private static let kTrailGreen  = "trailG"
    private static let kTrailBlue   = "trailB"
    private static let kHeadRed     = "headR"
    private static let kHeadGreen   = "headG"
    private static let kHeadBlue    = "headB"
    private static let kGlyphs      = "glyphs"

    // MARK: - Parameters
    // speed: average fall speed (speedMin = speed*0.4, speedMax = speed*1.6)
    // trailLen: 1 (short) – 15 (long); maps to fadeAlpha = 0.16 - trailLen*0.01
    private var colSize:   CGFloat = 14
    private var speed:     Double  = 1.25
    private var trailLen:  Double  = 12        // → fadeAlpha ≈ 0.04
    private var fadeAlpha: CGFloat { CGFloat(0.16 - trailLen * 0.01) }
    private var speedMin:  Double  { speed * 0.4 }
    private var speedMax:  Double  { speed * 1.6 }
    private var trailColor = NSColor(calibratedRed: 0,   green: 0.65, blue: 0,   alpha: 1)
    private var headColor  = NSColor(calibratedRed: 0.9, green: 1.0,  blue: 0.9, alpha: 1)

    private static let defaultGlyphs = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789"

    // MARK: - Animation state
    private var glyphs = Array(defaultGlyphs)
    private var numCols    = 0
    private var numRows    = 0
    private var drops:     [Double]       = []
    private var speeds:    [Double]       = []
    private var prevHeads: [Int]          = []
    private var grid:      [[Character?]] = []
    private var accumRep:  NSBitmapImageRep?
    private var repW = 0, repH = 0

    // MARK: - Sheet controls
    private var _sheet:        NSWindow?
    private var sizeSlider:    NSSlider!
    private var speedSlider:   NSSlider!
    private var trailSlider:   NSSlider!
    private var trailWell:     NSColorWell!
    private var headWell:      NSColorWell!
    private var glyphsView:    NSTextView!

    // MARK: - Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 20.0
        loadSettings()
        observeSettingsChanges()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 20.0
        loadSettings()
        observeSettingsChanges()
    }

    private static let settingsNotification = "sk.telepovsky.MatrixSaver.settingsChanged" as CFString

    private func observeSettingsChanges() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                Unmanaged<MatrixScreenSaverView>.fromOpaque(observer)
                    .takeUnretainedValue()
                    .applySettingsChange()
            },
            Self.settingsNotification,
            nil,
            .deliverImmediately
        )
    }

    private func applySettingsChange() {
        saverDefaults()?.synchronize()
        loadSettings()
        numCols = 0
        accumRep = nil
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(Self.settingsNotification),
            nil
        )
    }

    // MARK: - Settings persistence

    private func saverDefaults() -> ScreenSaverDefaults? {
        ScreenSaverDefaults(forModuleWithName: Self.moduleID)
    }

    private func loadSettings() {
        guard let d = saverDefaults() else { return }
        if d.object(forKey: Self.kColSize)  != nil { colSize  = CGFloat(d.float(forKey: Self.kColSize)) }
        if d.object(forKey: Self.kSpeed)    != nil { speed    = d.double(forKey: Self.kSpeed) }
        if d.object(forKey: Self.kTrailLen) != nil { trailLen = d.double(forKey: Self.kTrailLen) }

        let tr = d.object(forKey: Self.kTrailRed)   != nil ? CGFloat(d.float(forKey: Self.kTrailRed))   : 0.0
        let tg = d.object(forKey: Self.kTrailGreen) != nil ? CGFloat(d.float(forKey: Self.kTrailGreen)) : 0.65
        let tb = d.object(forKey: Self.kTrailBlue)  != nil ? CGFloat(d.float(forKey: Self.kTrailBlue))  : 0.0
        trailColor = NSColor(calibratedRed: tr, green: tg, blue: tb, alpha: 1)

        let hr = d.object(forKey: Self.kHeadRed)   != nil ? CGFloat(d.float(forKey: Self.kHeadRed))   : 0.9
        let hg = d.object(forKey: Self.kHeadGreen) != nil ? CGFloat(d.float(forKey: Self.kHeadGreen)) : 1.0
        let hb = d.object(forKey: Self.kHeadBlue)  != nil ? CGFloat(d.float(forKey: Self.kHeadBlue))  : 0.9
        headColor = NSColor(calibratedRed: hr, green: hg, blue: hb, alpha: 1)

        let str = d.string(forKey: Self.kGlyphs) ?? Self.defaultGlyphs
        glyphs = Array(str.isEmpty ? Self.defaultGlyphs : str)
    }

    private func saveSettings() {
        guard let d = saverDefaults() else { return }
        d.set(Float(colSize), forKey: Self.kColSize)
        d.set(speed,          forKey: Self.kSpeed)
        d.set(trailLen,       forKey: Self.kTrailLen)

        func storeColor(_ c: NSColor, r: String, g: String, b: String) {
            var rv: CGFloat = 0, gv: CGFloat = 0, bv: CGFloat = 0, av: CGFloat = 0
            (c.usingColorSpace(.genericRGB) ?? c).getRed(&rv, green: &gv, blue: &bv, alpha: &av)
            d.set(Float(rv), forKey: r); d.set(Float(gv), forKey: g); d.set(Float(bv), forKey: b)
        }
        storeColor(trailColor, r: Self.kTrailRed, g: Self.kTrailGreen, b: Self.kTrailBlue)
        storeColor(headColor,  r: Self.kHeadRed,  g: Self.kHeadGreen,  b: Self.kHeadBlue)
        d.set(String(glyphs), forKey: Self.kGlyphs)
        d.synchronize()
    }

    // MARK: - Animation

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
            bitmapDataPlanes: nil, pixelsWide: repW, pixelsHigh: repH,
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

        NSColor.black.withAlphaComponent(fadeAlpha).setFill()
        NSRect(x: 0, y: 0, width: CGFloat(repW), height: CGFloat(repH)).fill()

        let font       = NSFont.monospacedSystemFont(ofSize: colSize, weight: .regular)
        let trailAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: trailColor]
        let headAttrs:  [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: headColor]

        for i in 0..<numCols {
            let head = Int(drops[i])
            let x    = CGFloat(i) * colSize

            let start = max(0, prevHeads[i])
            for r in start..<max(start, head) {
                guard r < numRows else { break }
                if grid[i][r] == nil { grid[i][r] = glyphs.randomElement() }
                let y = CGFloat(repH) - CGFloat(r + 1) * colSize
                guard y > -colSize else { continue }
                NSAttributedString(string: String(grid[i][r]!), attributes: trailAttrs)
                    .draw(at: NSPoint(x: x, y: y))
            }

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

            if Int(drops[i]) >= numRows, Double.random(in: 0...1) < 0.3 {
                drops[i] = 0; prevHeads[i] = -1
                grid[i]  = Array(repeating: nil, count: numRows)
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

    // MARK: - Config sheet

    override var hasConfigureSheet: Bool { true }
    override var configureSheet: NSWindow? {
        _sheet = buildSheet()
        return _sheet
    }

    private func buildSheet() -> NSWindow {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 390),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        panel.title = "Matrix Rain"

        sizeSlider  = makeSlider(min: 8,    max: 24,  value: Double(colSize))
        speedSlider = makeSlider(min: 0.25, max: 4.0, value: speed)
        trailSlider = makeSlider(min: 1,    max: 15,  value: trailLen)
        trailWell   = makeColorWell(trailColor)
        headWell    = makeColorWell(headColor)
        let glyphsScroll = NSScrollView()
        glyphsScroll.translatesAutoresizingMaskIntoConstraints = false
        glyphsScroll.hasVerticalScroller = true
        glyphsScroll.hasHorizontalScroller = false
        glyphsScroll.borderType = .bezelBorder
        glyphsScroll.heightAnchor.constraint(equalToConstant: 70).isActive = true

        glyphsView = NSTextView()
        glyphsView.isEditable = true
        glyphsView.isRichText = false
        glyphsView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        glyphsView.string = String(glyphs)
        glyphsView.textContainer?.widthTracksTextView = true
        glyphsView.isHorizontallyResizable = false
        glyphsView.isVerticallyResizable = true
        glyphsView.autoresizingMask = [.width]
        glyphsScroll.documentView = glyphsView

        let rows: [(String, NSView)] = [
            ("Character Size:", sizeSlider),
            ("Rain Speed:",     speedSlider),
            ("Trail Length:",   trailSlider),
            ("Trail Color:",    trailWell),
            ("Head Color:",     headWell),
            ("Glyphs:",         glyphsScroll),
        ]

        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.spacing = 14
        vStack.translatesAutoresizingMaskIntoConstraints = false

        for (labelText, control) in rows {
            let label = NSTextField(labelWithString: labelText)
            label.alignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(equalToConstant: 120).isActive = true

            let row = NSStackView(views: [label, control])
            row.orientation = .horizontal
            row.spacing = 10
            row.alignment = .centerY
            vStack.addArrangedSubview(row)
        }

        let resetBtn  = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetClicked))
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        let okBtn     = NSButton(title: "OK",     target: self, action: #selector(okClicked))
        okBtn.keyEquivalent     = "\r"
        cancelBtn.keyEquivalent = "\u{1b}"

        let btnRow = NSStackView(views: [resetBtn, cancelBtn, okBtn])
        btnRow.orientation = .horizontal
        btnRow.spacing = 8
        btnRow.translatesAutoresizingMaskIntoConstraints = false

        let content = panel.contentView!
        content.addSubview(vStack)
        content.addSubview(btnRow)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            vStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            vStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            btnRow.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 20),
            btnRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            btnRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
        ])

        return panel
    }

    private func makeSlider(min: Double, max: Double, value: Double) -> NSSlider {
        let s = NSSlider(value: value, minValue: min, maxValue: max, target: nil, action: nil)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    private func makeColorWell(_ color: NSColor) -> NSColorWell {
        let w = NSColorWell()
        w.color = color
        w.translatesAutoresizingMaskIntoConstraints = false
        w.widthAnchor.constraint(equalToConstant: 44).isActive = true
        w.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return w
    }

    @objc private func okClicked(_ sender: Any) {
        colSize    = CGFloat(sizeSlider.doubleValue)
        speed      = speedSlider.doubleValue
        trailLen   = trailSlider.doubleValue
        trailColor = trailWell.color
        headColor  = headWell.color
        let str    = glyphsView.string
        glyphs     = Array(str.isEmpty ? Self.defaultGlyphs : str)
        saveSettings()
        numCols = 0; accumRep = nil   // force re-setup with new params
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.settingsNotification),
            nil, nil, true
        )
        _sheet!.sheetParent?.endSheet(_sheet!)
    }

    @objc private func resetClicked(_ sender: Any) {
        sizeSlider.doubleValue  = 14
        speedSlider.doubleValue = 1.25
        trailSlider.doubleValue = 12
        trailWell.color  = NSColor(calibratedRed: 0,   green: 0.65, blue: 0,   alpha: 1)
        headWell.color   = NSColor(calibratedRed: 0.9, green: 1.0,  blue: 0.9, alpha: 1)
        glyphsView.string = Self.defaultGlyphs
    }

    @objc private func cancelClicked(_ sender: Any) {
        _sheet!.sheetParent?.endSheet(_sheet!)
    }
}
