import Cocoa

private let endpoint = URL(string: "https://sira-gunluk.furkanturkkan25.workers.dev/api/sira")!

private let ink = NSColor.black
private let muted = NSColor.black
private let good = NSColor(srgbRed: 0.345, green: 0.655, blue: 0, alpha: 1)
private let blue = NSColor(srgbRed: 0.110, green: 0.690, blue: 0.965, alpha: 1)

private struct Person {
    let id: String
    let name: String
    let email: String
    let grade: Int
    let last: String
    let streak: Int
    let points: Int
    let active: Bool
}

private func face(_ size: CGFloat, heavy: Bool) -> NSFont {
    let name = heavy ? "AvenirNext-Bold" : "AvenirNext-Medium"
    return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: heavy ? .bold : .medium)
}

private final class LineCell: NSTableCellView {
    let field = FullLabel(labelWithString: "")

    init() {
        super.init(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        field.cell?.wraps = false
        field.cell?.isScrollable = false
        addSubview(field)
        textField = field
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { field.textColor = .black }
    }

    required init?(coder: NSCoder) { nil }
}

private final class FullLabel: NSTextField {
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        guard let font else { return size }
        size.height = ceil(font.ascender - font.descender) + 8
        size.width = ceil(size.width) + 4
        return size
    }
}

private func istanbulToday() -> String {
    let format = DateFormatter()
    format.calendar = Calendar(identifier: .gregorian)
    format.locale = Locale(identifier: "en_US_POSIX")
    format.timeZone = TimeZone(identifier: "Europe/Istanbul")
    format.dateFormat = "yyyy-MM-dd"
    return format.string(from: Date())
}

private func turkishDay(_ iso: String) -> String {
    let parse = DateFormatter()
    parse.calendar = Calendar(identifier: .gregorian)
    parse.locale = Locale(identifier: "en_US_POSIX")
    parse.timeZone = TimeZone(identifier: "Europe/Istanbul")
    parse.dateFormat = "yyyy-MM-dd"
    guard let date = parse.date(from: iso) else { return iso }
    let show = DateFormatter()
    show.locale = Locale(identifier: "tr_TR")
    show.timeZone = TimeZone(identifier: "Europe/Istanbul")
    show.dateFormat = "d MMMM yyyy"
    return show.string(from: date)
}

private func scorePoints(_ data: Data) -> [String: Int] {
    let node = "/opt/homebrew/bin/node"
    let script = "/Users/furkanturkkan/SiraMasa/score.mjs"
    guard FileManager.default.isExecutableFile(atPath: node) else { return [:] }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: node)
    process.arguments = [script]
    let input = Pipe()
    let output = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = Pipe()
    do {
        try process.run()
        input.fileHandleForWriting.write(data)
        try input.fileHandleForWriting.close()
        process.waitUntilExit()
        let result = output.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0,
              let parsed = try? JSONSerialization.jsonObject(with: result) as? [String: Any] else { return [:] }
        var scores: [String: Int] = [:]
        for (key, value) in parsed {
            if let number = value as? NSNumber { scores[key] = number.intValue }
        }
        return scores
    } catch {
        return [:]
    }
}

private func readPeople(from data: Data, today: String, points: [String: Int]) -> [Person]? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let accounts = json["accounts"] as? [[String: Any]] else { return nil }
    let streaks = json["streaks"] as? [String: [String: Any]] ?? [:]
    return accounts.compactMap { account in
        guard let name = account["name"] as? String, let id = account["id"] as? String else { return nil }
        let grade = account["grade"] as? Int ?? 0
        let display = (account["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let storedMail = (account["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = storedMail.isEmpty && name.contains("@") ? name : storedMail
        let shown: String
        if name.contains("@") {
            shown = display.isEmpty ? name : display
        } else if !display.isEmpty && display.caseInsensitiveCompare(name) != .orderedSame {
            shown = "\(name) · \(display)"
        } else {
            shown = name
        }
        let row = streaks[id]
        let last = row?["last"] as? String ?? ""
        let streak = row?["streak"] as? Int ?? 0
        return Person(id: id, name: shown, email: email, grade: grade, last: last, streak: streak, points: points[id] ?? 0, active: !last.isEmpty && last == today)
    }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
}

private final class Ground: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        bounds.fill()
        NSColor(srgbRed: 0.843, green: 1, blue: 0.722, alpha: 0.9).setFill()
        NSBezierPath(ovalIn: NSRect(x: -200, y: -180, width: 560, height: 440)).fill()
        NSColor(srgbRed: 0.867, green: 0.957, blue: 1, alpha: 0.95).setFill()
        NSBezierPath(ovalIn: NSRect(x: bounds.width - 300, y: bounds.height - 240, width: 480, height: 380)).fill()
    }
}

private final class Desk: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1100, height: 680),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    private let countLabel = FullLabel(labelWithString: "—")
    private let activeLabel = FullLabel(labelWithString: "—")
    private let status = NSTextField(wrappingLabelWithString: "Bakılıyor")
    private let table = NSTableView()
    private let pickedName = FullLabel(labelWithString: "Değiştirmek için bir hesap seç.")
    private let emailField = NSTextField()
    private let streakField = NSTextField()
    private let pointsField = NSTextField()
    private let passwordField = NSSecureTextField()
    private var people: [Person] = []
    private var latestStore: Data?
    private var saving = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        build()
        reload()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func build() {
        window.appearance = NSAppearance(named: .aqua)
        window.title = "Sıra"
        window.minSize = NSSize(width: 980, height: 520)
        window.backgroundColor = .white
        let ground = Ground()
        window.contentView = ground

        let brand = label("Sıra", size: 28, heavy: true, color: good)
        let line = label("Açılan hesaplar ve bugün girenler.", size: 16, heavy: false, color: muted)
        status.font = face(15, heavy: false)
        status.textColor = muted
        status.maximumNumberOfLines = 3
        status.lineBreakMode = .byWordWrapping
        status.cell?.wraps = true
        status.cell?.isScrollable = false

        styleNumber(countLabel, color: .black)
        styleNumber(activeLabel, color: .black)
        let countCaption = label("hesap", size: 16, heavy: true, color: muted)
        let activeCaption = label("bugün giren", size: 16, heavy: true, color: muted)

        let button = NSButton(title: "Yenile", target: self, action: #selector(reload))
        button.bezelStyle = .rounded
        button.font = face(14, heavy: true)
        button.contentTintColor = .black
        button.attributedTitle = NSAttributedString(string: "Yenile", attributes: [
            .foregroundColor: NSColor.black,
            .font: face(14, heavy: true),
        ])

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        table.style = .plain
        table.rowHeight = 46
        table.intercellSpacing = NSSize(width: 12, height: 4)
        table.backgroundColor = .clear
        table.headerView = NSTableHeaderView()
        table.selectionHighlightStyle = .regular
        table.allowsEmptySelection = true
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.dataSource = self
        table.delegate = self
        for (id, title, width) in [("name", "Ad", 180), ("email", "E-posta", 280), ("grade", "Sınıf", 100), ("last", "Son gün", 160), ("streak", "Seri", 70), ("points", "Puan", 80)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = CGFloat(width)
            column.minWidth = CGFloat(width)
            column.headerCell = BlackHeaderCell()
            column.headerCell.stringValue = title
            column.headerCell.font = face(14, heavy: true)
            column.headerCell.alignment = .left
            table.addTableColumn(column)
        }
        table.headerView?.frame.size.height = 34
        scroll.documentView = table

        pickedName.font = face(15, heavy: true)
        pickedName.textColor = .black
        styleEditor(emailField, placeholder: "E-posta")
        styleEditor(streakField, placeholder: "Seri")
        styleEditor(pointsField, placeholder: "Puan")
        styleEditor(passwordField, placeholder: "Yeni şifre")
        let remove = NSButton(title: "Sil", target: self, action: #selector(deleteAccount))
        remove.bezelStyle = .rounded
        remove.font = face(15, heavy: true)
        remove.contentTintColor = .black
        remove.attributedTitle = NSAttributedString(string: "Sil", attributes: [
            .foregroundColor: NSColor.black,
            .font: face(15, heavy: true),
        ])
        let save = NSButton(title: "Kaydet", target: self, action: #selector(saveEdit))
        save.bezelStyle = .rounded
        save.font = face(15, heavy: true)
        save.contentTintColor = .black
        save.attributedTitle = NSAttributedString(string: "Kaydet", attributes: [
            .foregroundColor: NSColor.black,
            .font: face(15, heavy: true),
        ])
        let emailCaption = label("E-posta", size: 14, heavy: true, color: .black)
        let streakCaption = label("Seri", size: 14, heavy: true, color: .black)
        let pointsCaption = label("Puan", size: 14, heavy: true, color: .black)
        let passwordCaption = label("Yeni şifre", size: 14, heavy: true, color: .black)

        let views = [brand, line, countLabel, countCaption, activeLabel, activeCaption, button, status, scroll, pickedName, emailCaption, emailField, streakCaption, streakField, pointsCaption, pointsField, passwordCaption, passwordField, save, remove]
        for view in views { view.translatesAutoresizingMaskIntoConstraints = false; ground.addSubview(view) }

        let guide = ground.layoutMarginsGuide
        NSLayoutConstraint.activate([
            brand.leadingAnchor.constraint(equalTo: ground.leadingAnchor, constant: 36),
            brand.topAnchor.constraint(equalTo: ground.topAnchor, constant: 28),
            button.trailingAnchor.constraint(equalTo: ground.trailingAnchor, constant: -32),
            button.centerYAnchor.constraint(equalTo: brand.centerYAnchor),

            line.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            line.topAnchor.constraint(equalTo: brand.bottomAnchor, constant: 4),
            line.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -16),

            countLabel.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            countLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 18),
            countCaption.leadingAnchor.constraint(equalTo: countLabel.leadingAnchor),
            countCaption.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 0),

            activeLabel.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 56),
            activeLabel.topAnchor.constraint(equalTo: countLabel.topAnchor),
            activeCaption.leadingAnchor.constraint(equalTo: activeLabel.leadingAnchor),
            activeCaption.topAnchor.constraint(equalTo: activeLabel.bottomAnchor, constant: 0),

            status.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            status.trailingAnchor.constraint(equalTo: ground.trailingAnchor, constant: -32),
            status.topAnchor.constraint(equalTo: countCaption.bottomAnchor, constant: 16),

            scroll.leadingAnchor.constraint(equalTo: ground.leadingAnchor, constant: 28),
            scroll.trailingAnchor.constraint(equalTo: ground.trailingAnchor, constant: -20),
            scroll.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 12),
            scroll.bottomAnchor.constraint(equalTo: pickedName.topAnchor, constant: -12),

            pickedName.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            pickedName.trailingAnchor.constraint(equalTo: ground.trailingAnchor, constant: -32),
            pickedName.bottomAnchor.constraint(equalTo: emailField.topAnchor, constant: -8),

            emailCaption.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            emailCaption.centerYAnchor.constraint(equalTo: emailField.centerYAnchor),
            emailField.leadingAnchor.constraint(equalTo: emailCaption.trailingAnchor, constant: 8),
            emailField.trailingAnchor.constraint(equalTo: ground.trailingAnchor, constant: -32),
            emailField.heightAnchor.constraint(equalToConstant: 28),
            emailField.bottomAnchor.constraint(equalTo: streakField.topAnchor, constant: -10),

            streakCaption.leadingAnchor.constraint(equalTo: brand.leadingAnchor),
            streakCaption.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            streakField.leadingAnchor.constraint(equalTo: streakCaption.trailingAnchor, constant: 8),
            streakField.widthAnchor.constraint(equalToConstant: 72),
            streakField.bottomAnchor.constraint(equalTo: ground.bottomAnchor, constant: -22),

            pointsCaption.leadingAnchor.constraint(equalTo: streakField.trailingAnchor, constant: 16),
            pointsCaption.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            pointsField.leadingAnchor.constraint(equalTo: pointsCaption.trailingAnchor, constant: 8),
            pointsField.widthAnchor.constraint(equalToConstant: 84),

            passwordCaption.leadingAnchor.constraint(equalTo: pointsField.trailingAnchor, constant: 16),
            passwordCaption.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            passwordField.leadingAnchor.constraint(equalTo: passwordCaption.trailingAnchor, constant: 8),
            passwordField.widthAnchor.constraint(equalToConstant: 150),

            streakField.heightAnchor.constraint(equalToConstant: 28),
            pointsField.heightAnchor.constraint(equalToConstant: 28),
            passwordField.heightAnchor.constraint(equalToConstant: 28),
            save.leadingAnchor.constraint(equalTo: passwordField.trailingAnchor, constant: 16),
            save.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            remove.leadingAnchor.constraint(equalTo: save.trailingAnchor, constant: 8),
            remove.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            pointsField.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
            passwordField.centerYAnchor.constraint(equalTo: streakField.centerYAnchor),
        ])
        _ = guide

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func label(_ text: String, size: CGFloat, heavy: Bool, color: NSColor) -> NSTextField {
        let field = FullLabel(labelWithString: text)
        field.font = face(size, heavy: heavy)
        field.textColor = color
        field.lineBreakMode = .byClipping
        field.cell?.wraps = false
        field.cell?.isScrollable = false
        field.setContentCompressionResistancePriority(.required, for: .vertical)
        return field
    }

    private func styleNumber(_ field: NSTextField, color: NSColor) {
        field.font = face(52, heavy: true)
        field.textColor = color
        field.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @objc private func reload() {
        status.stringValue = "Bakılıyor"
        let today = istanbulToday()
        URLSession.shared.dataTask(with: endpoint) { data, response, _ in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let parsed = data.flatMap { readPeople(from: $0, today: today, points: scorePoints($0)) }
            DispatchQueue.main.async {
                guard code == 200, let parsed else {
                    self.status.stringValue = "Liste alınamadı. Yenile."
                    return
                }
                let keep = self.table.selectedRow >= 0 && self.table.selectedRow < self.people.count ? self.people[self.table.selectedRow].id : nil
                self.latestStore = data
                self.people = parsed
                self.countLabel.stringValue = "\(parsed.count)"
                self.activeLabel.stringValue = "\(parsed.filter(\.active).count)"
                self.status.stringValue = "Bir hesap seç. E-posta, seri, puan ya da yeni şifreyi yazıp kaydet."
                let width = self.window.contentView?.bounds.width ?? 760
                self.status.preferredMaxLayoutWidth = width - 68
                self.table.reloadData()
                if let keep, let row = parsed.firstIndex(where: { $0.id == keep }) {
                    self.table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                    self.fill(parsed[row])
                } else {
                    self.table.deselectAll(nil)
                    self.pickedName.stringValue = "Değiştirmek için bir hesap seç."
                    self.emailField.stringValue = ""
                    self.streakField.stringValue = ""
                    self.pointsField.stringValue = ""
                    self.passwordField.stringValue = ""
                }
            }
        }.resume()
    }

    private func styleEditor(_ field: NSTextField, placeholder: String) {
        field.placeholderString = placeholder
        field.font = face(16, heavy: true)
        field.textColor = .black
        field.backgroundColor = .white
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
    }

    private func fill(_ person: Person) {
        pickedName.stringValue = person.name
        emailField.stringValue = person.email
        streakField.stringValue = "\(person.streak)"
        pointsField.stringValue = "\(person.points)"
        passwordField.stringValue = ""
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = table.selectedRow
        guard row >= 0, row < people.count else { return }
        fill(people[row])
    }

    @objc private func deleteAccount() {
        let row = table.selectedRow
        guard row >= 0, row < people.count else {
            status.stringValue = "Önce listeden bir hesap seç."
            return
        }
        if saving { return }
        let person = people[row]
        let alert = NSAlert()
        alert.messageText = "\(person.name) silinsin mi?"
        alert.informativeText = "Hesap, puanı ve mesajları kalkar. Bu geri alınmaz."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Sil")
        alert.addButton(withTitle: "Vazgeç")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let payload: [String: Any] = [
            "accounts": [Any](),
            "answers": [String: Any](),
            "streaks": [String: Any](),
            "threads": [Any](),
            "trials": [String: Any](),
            "deleted": [person.id],
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        saving = true
        status.stringValue = "Siliniyor"
        post(body)
    }

    @objc private func saveEdit() {
        let row = table.selectedRow
        guard row >= 0, row < people.count, let store = latestStore else {
            status.stringValue = "Önce listeden bir hesap seç."
            return
        }
        if saving { return }
        guard let streak = Int(streakField.stringValue.trimmingCharacters(in: .whitespaces)), streak >= 0,
              let points = Int(pointsField.stringValue.trimmingCharacters(in: .whitespaces)), points >= 0 else {
            status.stringValue = "Seri ve puan sayı olsun."
            return
        }
        let password = passwordField.stringValue
        if !password.isEmpty && password.count < 4 {
            status.stringValue = "Şifre en az dört karakter olsun."
            return
        }
        let email = emailField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty && email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) == nil {
            status.stringValue = "Geçerli bir e-posta yaz."
            return
        }
        guard let storeObject = try? JSONSerialization.jsonObject(with: store),
              let body = try? JSONSerialization.data(withJSONObject: [
                "id": people[row].id,
                "streak": streak,
                "points": points,
                "password": password,
                "email": email,
                "store": storeObject,
              ]) else {
            status.stringValue = "Liste okunamadı. Yenile."
            return
        }
        saving = true
        status.stringValue = "Kaydediliyor"
        DispatchQueue.global(qos: .userInitiated).async {
            let edited = self.runEdit(body)
            DispatchQueue.main.async {
                self.saving = false
                guard let patch = edited.data else {
                    self.status.stringValue = edited.error
                    return
                }
                self.post(patch)
            }
        }
    }

    private func runEdit(_ body: Data) -> (data: Data?, error: String) {
        let node = "/opt/homebrew/bin/node"
        let script = "/Users/furkanturkkan/SiraMasa/edit.mjs"
        guard FileManager.default.isExecutableFile(atPath: node) else { return (nil, "Kayıt aracı bulunamadı.") }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: node)
        process.arguments = [script]
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors
        do {
            try process.run()
            input.fileHandleForWriting.write(body)
            try input.fileHandleForWriting.close()
            process.waitUntilExit()
            let result = output.fileHandleForReading.readDataToEndOfFile()
            if process.terminationStatus != 0 || result.isEmpty {
                let message = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (nil, message?.isEmpty == false ? message! : "Kaydedilemedi.")
            }
            return (result, "")
        } catch {
            return (nil, "Kaydedilemedi.")
        }
    }

    private func post(_ body: Data) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { _, response, _ in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                self.saving = false
                guard code == 200 else {
                    self.status.stringValue = "Kaydedilemedi. Yenile."
                    return
                }
                self.passwordField.stringValue = ""
                self.reload()
            }
        }.resume()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { people.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = tableColumn?.identifier.rawValue ?? "name"
        let reuse = NSUserInterfaceItemIdentifier(id)
        let cell = tableView.makeView(withIdentifier: reuse, owner: self) as? LineCell ?? LineCell()
        cell.identifier = reuse
        cell.field.font = face(16, heavy: id == "name" || id == "email")
        let person = people[row]
        switch id {
        case "email": cell.field.stringValue = person.email.isEmpty ? "yok" : person.email
        case "grade": cell.field.stringValue = person.grade > 0 ? "\(person.grade). sınıf" : ""
        case "last": cell.field.stringValue = person.last.isEmpty ? "henüz yok" : turkishDay(person.last)
        case "streak": cell.field.stringValue = "\(person.streak)"
        case "points": cell.field.stringValue = "\(person.points)"
        default: cell.field.stringValue = person.name
        }
        cell.field.textColor = .black
        return cell
    }
}

private final class BlackHeaderCell: NSTableHeaderCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        NSColor.white.setFill()
        cellFrame.fill()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        let text = NSAttributedString(string: stringValue, attributes: [
            .font: face(14, heavy: true),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph,
        ])
        let size = text.size()
        let rect = cellFrame.insetBy(dx: 6, dy: 0)
        text.draw(in: NSRect(x: rect.minX, y: rect.minY + (rect.height - size.height) / 2, width: rect.width, height: size.height))
    }
}

let app = NSApplication.shared
app.appearance = NSAppearance(named: .aqua)
private let desk = Desk()
app.setActivationPolicy(.regular)
app.delegate = desk
app.run()
