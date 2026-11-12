import Foundation

public struct Article: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let urlHash: String
    public let titleIt: String
    public let originalTitle: String?
    public let summaryPoints: [String]
    public let actionMitigation: String?
    public let threatLevel: ThreatLevel
    public let category: NewsCategory
    public let targetAudience: String?
    public let tags: [String]
    public let sourceName: String
    public let sourceUrl: String
    public let publishedAt: String?
    public let createdAt: String?
    public let isBreaking: Bool?
    public let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case urlHash = "url_hash"
        case titleIt = "title_it"
        case originalTitle = "original_title"
        case summaryPoints = "summary_points"
        case actionMitigation = "action_mitigation"
        case threatLevel = "threat_level"
        case category
        case targetAudience = "target_audience"
        case tags
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case isBreaking = "is_breaking"
        case audioUrl = "audio_url"
    }

    public init(
        id: String,
        urlHash: String,
        titleIt: String,
        originalTitle: String? = nil,
        summaryPoints: [String],
        actionMitigation: String? = nil,
        threatLevel: ThreatLevel,
        category: NewsCategory,
        targetAudience: String? = nil,
        tags: [String] = [],
        sourceName: String,
        sourceUrl: String,
        publishedAt: String? = nil,
        createdAt: String? = nil,
        isBreaking: Bool? = false,
        audioUrl: String? = nil
    ) {
        self.id = id
        self.urlHash = urlHash
        self.titleIt = titleIt
        self.originalTitle = originalTitle
        self.summaryPoints = summaryPoints
        self.actionMitigation = actionMitigation
        self.threatLevel = threatLevel
        self.category = category
        self.targetAudience = targetAudience
        self.tags = tags
        self.sourceName = sourceName
        self.sourceUrl = sourceUrl
        self.publishedAt = publishedAt
        self.createdAt = createdAt
        self.isBreaking = isBreaking
        self.audioUrl = audioUrl
    }

    /// URL pubblico dell'audio neurale generato per questo articolo (streaming broadcast HD)
    public var resolvedAudioUrl: String? {
        if let audioUrl = audioUrl, !audioUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return audioUrl
        }
        if !id.isEmpty {
            return "https://stkmmwwpwrbnkigkuwdp.supabase.co/storage/v1/object/public/news-audio/\(id).mp3"
        }
        return nil
    }

    /// Data effettiva di pubblicazione / inserimento dell'articolo (usata per l'ordinamento cronologico rigoroso)
    public var effectiveDate: Date {
        ArticleDateParser.parseDate(publishedAt: publishedAt, createdAt: createdAt)
    }

    /// Tempo relativo in italiano perfetto ed elegante (es. "5 min fa", "2 ore fa", "Oggi, 15:45", "Ieri, 11:20")
    public var formattedRelativeTime: String {
        ArticleDateParser.formatRelativeTime(for: effectiveDate, originalString: publishedAt)
    }

    /// Lista di tutte le fonti individuali verificate citate (es. ["BleepingComputer", "Cybersecurity360"])
    public var sourceNamesList: [String] {
        let raw = sourceName.components(separatedBy: ",")
        let cleaned = raw.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? [sourceName] : cleaned
    }

    /// Nome sintetico e pulito della fonte principale (evita stringhe composite troppo lunghe nella card)
    public var primarySourceName: String {
        let first = sourceNamesList.first ?? sourceName
        switch first {
        case "Presidenza del Consiglio":
            return "Governo IT"
        default:
            return first
        }
    }

    /// Numero di ulteriori fonti verificate per questa notizia (es. +1, +2)
    public var additionalSourcesCount: Int {
        max(0, sourceNamesList.count - 1)
    }

    /// Tutte le fonti formattate per la vista estesa di dettaglio
    public var allSourcesDisplay: String {
        sourceNamesList.joined(separator: " • ")
    }

    /// Riconoscimento automatico delle vulnerabilità CVE citate nel testo e nei tag
    public var detectedCVEs: [String] {
        let pattern = #"\bCVE-\d{4}-\d{4,7}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        var textPool = "\(titleIt) \(originalTitle ?? "") \(actionMitigation ?? "") \(tags.joined(separator: " "))"
        for point in summaryPoints {
            textPool += " \(point)"
        }

        let range = NSRange(textPool.startIndex..<textPool.endIndex, in: textPool)
        let matches = regex.matches(in: textPool, options: [], range: range)

        var result: [String] = []
        for match in matches {
            if let swiftRange = Range(match.range, in: textPool) {
                let cve = String(textPool[swiftRange]).uppercased()
                if !result.contains(cve) {
                    result.append(cve)
                }
            }
        }
        return result
    }
}

// MARK: - Comparable per ordinamento cronologico automatico
extension Article: Comparable {
    public static func < (lhs: Article, rhs: Article) -> Bool {
        lhs.effectiveDate < rhs.effectiveDate
    }
}

// MARK: - Parser Data e Formattatore Relativo Intelligente
public enum ArticleDateParser {
    nonisolated(unsafe) private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let isoFormatterStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    nonisolated(unsafe) private static let rfc822Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    nonisolated(unsafe) private static let rfc822WithTimezoneNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    nonisolated(unsafe) private static let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    nonisolated(unsafe) private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    nonisolated(unsafe) private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    public static func parseDate(publishedAt: String?, createdAt: String?) -> Date {
        // 1. Prova a parsare publishedAt se presente
        if let pub = publishedAt?.trimmingCharacters(in: .whitespacesAndNewlines), !pub.isEmpty {
            if let date = parseSingleDateString(pub) {
                return date
            }
        }

        // 2. Prova con createdAt (timestamp ISO 8601 con frazioni di secondo fornito da Supabase)
        if let cr = createdAt?.trimmingCharacters(in: .whitespacesAndNewlines), !cr.isEmpty {
            if let date = parseSingleDateString(cr) {
                return date
            }
        }

        return Date.distantPast
    }

    private static func parseSingleDateString(_ str: String) -> Date? {
        // ISO 8601 con microsecondi
        if let d = isoFormatterWithFractional.date(from: str) {
            return d
        }
        // ISO 8601 standard
        if let d = isoFormatterStandard.date(from: str) {
            return d
        }
        // RFC822 (+0000, +0530, ecc.)
        if let d = rfc822Formatter.date(from: str) {
            return d
        }
        // RFC822 con GMT / UTC
        if let d = rfc822WithTimezoneNameFormatter.date(from: str) {
            return d
        }
        // Formato semplice yyyy-MM-dd HH:mm:ss
        if let d = simpleDateFormatter.date(from: str) {
            return d
        }

        // Gestione stringhe relative italiane
        let lower = str.lowercased()
        let now = Date()
        let calendar = Calendar.current

        // "Oggi, HH:mm"
        if lower.starts(with: "oggi") {
            if let timePart = extractTime(from: str),
               let timeDate = timeOnlyFormatter.date(from: timePart) {
                let timeComps = calendar.dateComponents([.hour, .minute], from: timeDate)
                return calendar.date(bySettingHour: timeComps.hour ?? 12, minute: timeComps.minute ?? 0, second: 0, of: now) ?? now
            }
            return now
        }

        // "Ieri, HH:mm"
        if lower.starts(with: "ieri") {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            if let timePart = extractTime(from: str),
               let timeDate = timeOnlyFormatter.date(from: timePart) {
                let timeComps = calendar.dateComponents([.hour, .minute], from: timeDate)
                return calendar.date(bySettingHour: timeComps.hour ?? 12, minute: timeComps.minute ?? 0, second: 0, of: yesterday) ?? yesterday
            }
            return yesterday
        }

        // "X min fa"
        if lower.contains("min") && lower.contains("fa") {
            let num = extractFirstInt(from: str) ?? 15
            return calendar.date(byAdding: .minute, value: -num, to: now)
        }

        // "X ore fa" o "1 ora fa"
        if lower.contains("or") && lower.contains("fa") {
            let num = extractFirstInt(from: str) ?? 2
            return calendar.date(byAdding: .hour, value: -num, to: now)
        }

        // "X giorni fa" o "1 giorno fa"
        if lower.contains("giorn") && lower.contains("fa") {
            let num = extractFirstInt(from: str) ?? 1
            return calendar.date(byAdding: .day, value: -num, to: now)
        }

        // "X settimane fa" o "1 settimana fa"
        if lower.contains("settiman") && lower.contains("fa") {
            let num = extractFirstInt(from: str) ?? 1
            return calendar.date(byAdding: .day, value: -(num * 7), to: now)
        }

        // "X mesi fa" o "1 mese fa"
        if lower.contains("mes") && lower.contains("fa") {
            let num = extractFirstInt(from: str) ?? 1
            return calendar.date(byAdding: .month, value: -num, to: now)
        }

        return nil
    }

    private static func extractTime(from str: String) -> String? {
        let parts = str.components(separatedBy: CharacterSet(charactersIn: ", -/"))
        for p in parts {
            let clean = p.trimmingCharacters(in: .whitespaces)
            if clean.contains(":") && clean.count >= 4 && clean.count <= 5 {
                return clean
            }
        }
        return nil
    }

    private static func extractFirstInt(from str: String) -> Int? {
        let scanner = Scanner(string: str)
        while !scanner.isAtEnd {
            if let num = scanner.scanInt() {
                return num
            }
            _ = scanner.scanCharacter()
        }
        return nil
    }

    public static func formatRelativeTime(for date: Date, originalString: String?) -> String {
        // Se la stringa originale è già una bella etichetta italiana (es. "Oggi, 15:45", "Ieri, 11:20", "25 min fa"), preservala
        if let orig = originalString?.trimmingCharacters(in: .whitespacesAndNewlines), !orig.isEmpty {
            let lower = orig.lowercased()
            if lower.starts(with: "oggi") || lower.starts(with: "ieri") || lower.contains(" fa") {
                return orig
            }
        }

        guard date != Date.distantPast else { return "Recente" }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 && interval >= 0 {
            return "Adesso"
        } else if interval < 3600 && interval >= 60 {
            let mins = max(1, Int(interval / 60))
            return "\(mins) min fa"
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let hours = max(1, Int(interval / 3600))
            if hours < 4 {
                return hours == 1 ? "1 ora fa" : "\(hours) ore fa"
            } else {
                return "Oggi, \(timeOnlyFormatter.string(from: date))"
            }
        } else if calendar.isDateInYesterday(date) {
            return "Ieri, \(timeOnlyFormatter.string(from: date))"
        }

        let days = Int(interval / 86400)
        if days >= 1 && days < 7 {
            return days == 1 ? "1 giorno fa" : "\(days) giorni fa"
        } else if days >= 7 && days < 30 {
            let weeks = max(1, days / 7)
            return weeks == 1 ? "1 settimana fa" : "\(weeks) settimane fa"
        } else if days >= 30 && days < 90 {
            let months = max(1, days / 30)
            return months == 1 ? "1 mese fa" : "\(months) mesi fa"
        } else {
            return dayMonthFormatter.string(from: date)
        }
    }
}
