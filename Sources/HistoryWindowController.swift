import AppKit

// MARK: - History Window Controller

class HistoryWindowController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
    var history: [NotificationHistoryEntry] = []
    var tableView: NSTableView!

    // Cached formatter — creating DateFormatter is expensive; reuse across cell renders
    private let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt
    }()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notification History"
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
        window.contentView = buildContentView()
    }

    func loadHistory(_ entries: [NotificationHistoryEntry]) {
        history = entries
        tableView?.reloadData()
    }

    private func buildContentView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 400))

        let clearButton = NSButton(title: "Clear History", target: self, action: #selector(clearTapped))
        clearButton.bezelStyle = .rounded
        clearButton.frame = NSRect(x: 20, y: 8, width: 120, height: 28)
        view.addSubview(clearButton)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 44, width: 520, height: 356))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true

        let timeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("time"))
        timeCol.title = "Time"
        timeCol.width = 80
        tableView.addTableColumn(timeCol)

        let titleCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleCol.title = "Title"
        titleCol.width = 120
        tableView.addTableColumn(titleCol)

        let messageCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("message"))
        messageCol.title = "Message"
        messageCol.width = 280
        tableView.addTableColumn(messageCol)

        scrollView.documentView = tableView
        view.addSubview(scrollView)

        return view
    }

    @objc func clearTapped() {
        history = []
        if let d = NSApp.delegate as? AppDelegate {
            d.notificationHistory = []
        }
        tableView?.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return history.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let entry = history[row]
        switch tableColumn?.identifier.rawValue {
        case "time":
            return timeFormatter.string(from: entry.timestamp)
        case "title":
            return entry.title
        case "message":
            return entry.message
        default:
            return nil
        }
    }
}
