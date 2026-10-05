import AppKit

private struct Indicator: Equatable {
    var x: CGFloat
    var opacity: CGFloat

    func moved(toward target: Indicator, progress: CGFloat) -> Indicator {
        Indicator(
            x: x + (target.x - x) * progress,
            opacity: opacity + (target.opacity - opacity) * progress
        )
    }
}

private struct IndicatorPositions: Equatable {
    var workspace: Indicator
    var app: Indicator

    func moved(toward target: IndicatorPositions, progress: CGFloat) -> IndicatorPositions {
        IndicatorPositions(
            workspace: workspace.moved(toward: target.workspace, progress: progress),
            app: app.moved(toward: target.app, progress: progress)
        )
    }
}

private struct WorkspacePosition {
    let group: WorkspaceGroup
    let separatorX: CGFloat?
    let labelX: CGFloat
    let appXs: [CGFloat]
}

private struct StatusLayout {
    let width: CGFloat
    let workspaces: [WorkspacePosition]
    let workspaceIndicatorX: CGFloat?
    let appIndicatorX: CGFloat?

    init(groups: [WorkspaceGroup]) {
        var x: CGFloat = 4
        var positions: [WorkspacePosition] = []
        var workspaceIndicatorX: CGFloat?
        var appIndicatorX: CGFloat?

        for (index, group) in groups.enumerated() {
            let separatorX: CGFloat? = index == 0 ? nil : x + 3
            if index > 0 { x += 15 }
            let labelX = x
            if group.workspace.isFocused { workspaceIndicatorX = labelX + (16 - 9) / 2 }
            x += 16
            var appXs: [CGFloat] = []
            for app in group.apps {
                appXs.append(x)
                if app.bundleID == group.focusedAppBundleID { appIndicatorX = x + 7 }
                x += 20
            }
            positions.append(WorkspacePosition(
                group: group, separatorX: separatorX, labelX: labelX, appXs: appXs
            ))
        }

        width = x + 4
        workspaces = positions
        self.workspaceIndicatorX = workspaceIndicatorX
        self.appIndicatorX = appIndicatorX
    }
}

private final class MenuBarApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let client = AeroSpaceClient()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var timer: Timer?
    private var isRefreshing = false
    private var refreshPending = false
    private var events: AeroSpaceEvents?
    private var currentGroups: [WorkspaceGroup] = []
    private var currentLayout: StatusLayout?
    private var lastError: String?
    private var icons: [String: NSImage] = [:]
    private var displayedIndicators: IndicatorPositions?
    private var animationTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "AeroSpace workspaces"
        menu.delegate = self
        statusItem.menu = menu
        render()
        refresh()
        events = AeroSpaceEvents(onChange: { [weak self] in self?.refresh() })
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.events?.ensureRunning()
            self?.refresh()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        animationTimer?.invalidate()
        timer?.invalidate()
        events?.stop()
    }

    private func refresh() {
        guard !isRefreshing else {
            refreshPending = true
            return
        }
        isRefreshing = true
        let previousAppOrder = Dictionary(uniqueKeysWithValues: currentGroups.map {
            ($0.workspace.name, $0.apps.map(\.bundleID))
        })
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let result = Result { try self.client.snapshot(previousAppOrder: previousAppOrder) }
            DispatchQueue.main.async {
                self.isRefreshing = false
                switch result {
                case .success(let groups):
                    self.currentGroups = groups
                    self.currentLayout = StatusLayout(groups: groups)
                    self.lastError = nil
                    self.animateIndicators()
                case .failure(let error):
                    self.lastError = error.localizedDescription
                    self.render()
                }
                if self.refreshPending {
                    self.refreshPending = false
                    self.refresh()
                }
            }
        }
    }

    private func animateIndicators() {
        guard let layout = currentLayout else { return }
        let previous = displayedIndicators
        let target = IndicatorPositions(
            workspace: Indicator(
                x: layout.workspaceIndicatorX ?? previous?.workspace.x ?? 0,
                opacity: layout.workspaceIndicatorX == nil ? 0 : 1
            ),
            app: Indicator(
                x: layout.appIndicatorX ?? previous?.app.x ?? 0,
                opacity: layout.appIndicatorX == nil ? 0 : 1
            )
        )
        animationTimer?.invalidate()
        guard let previous, previous != target else {
            displayedIndicators = target
            render()
            return
        }

        let start = ProcessInfo.processInfo.systemUptime
        let duration = 0.28
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            let fraction = CGFloat(min(1, elapsed / duration))
            let eased = fraction * fraction * (3 - 2 * fraction)
            self.displayedIndicators = previous.moved(toward: target, progress: eased)
            self.render()
            if fraction >= 1 {
                timer.invalidate()
                self.animationTimer = nil
            }
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        render()
    }

    private func render() {
        statusItem.button?.image = makeImage()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if let lastError {
            let item = NSMenuItem(title: lastError, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for group in currentGroups {
                let names = group.apps.map(\.appName).joined(separator: ", ")
                let title = "\(group.workspace.name)  \(names.isEmpty ? "Empty" : names)"
                let item = NSMenuItem(title: title, action: #selector(selectWorkspace(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = group.workspace.name
                item.state = group.workspace.isFocused ? .on : .off
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func makeImage() -> NSImage {
        if lastError != nil {
            return textImage("AeroSpace ⚠")
        }
        guard let layout = currentLayout, !layout.workspaces.isEmpty else {
            return textImage("AeroSpace…")
        }

        let iconSize: CGFloat = 16
        let height: CGFloat = 22
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        let labelAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        let separatorAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.secondaryLabelColor]
        let indicators = displayedIndicators
        let image = NSImage(size: NSSize(width: layout.width, height: height), flipped: false) { [self] _ in
            for position in layout.workspaces {
                if let separatorX = position.separatorX {
                    ("|" as NSString).draw(at: NSPoint(x: separatorX, y: 3), withAttributes: separatorAttributes)
                }
                let label = position.group.workspace.name as NSString
                let labelWidth = label.size(withAttributes: labelAttributes).width
                label.draw(at: NSPoint(x: position.labelX + (16 - labelWidth) / 2, y: 3),
                           withAttributes: labelAttributes)
                for (app, x) in zip(position.group.apps, position.appXs) {
                    icon(for: app.bundleID).draw(in: NSRect(x: x, y: 4, width: iconSize, height: iconSize))
                }
            }
            if let workspace = indicators?.workspace, workspace.opacity > 0 {
                NSColor.controlAccentColor.withAlphaComponent(workspace.opacity).setFill()
                NSBezierPath(roundedRect: NSRect(x: workspace.x, y: 1, width: 9, height: 2),
                             xRadius: 1, yRadius: 1).fill()
            }
            if let app = indicators?.app, app.opacity > 0 {
                let dot = NSBezierPath(ovalIn: NSRect(x: app.x, y: 0.5, width: 3, height: 3))
                NSColor.white.withAlphaComponent(app.opacity).setFill()
                dot.fill()
                NSColor.black.withAlphaComponent(0.35 * app.opacity).setStroke()
                dot.lineWidth = 0.5
                dot.stroke()
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    private func textImage(_ title: String) -> NSImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
        ]
        let size = (title as NSString).size(withAttributes: attributes)
        return NSImage(size: NSSize(width: size.width + 8, height: 22), flipped: false) { _ in
            (title as NSString).draw(at: NSPoint(x: 4, y: 3), withAttributes: attributes)
            return true
        }
    }

    private func icon(for bundleID: String) -> NSImage {
        if let cached = icons[bundleID] { return cached }
        let image: NSImage
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            image = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            image = NSImage(named: NSImage.applicationIconName) ?? NSImage()
        }
        icons[bundleID] = image
        return image
    }

    @objc private func selectWorkspace(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do { try self.client.switchToWorkspace(name) }
            catch {
                DispatchQueue.main.async { self.lastError = error.localizedDescription; self.render() }
            }
            DispatchQueue.main.async { self.refresh() }
        }
    }

    @objc private func refreshNow() { refresh() }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
private let delegate = MenuBarApp()
app.delegate = delegate
app.run()
