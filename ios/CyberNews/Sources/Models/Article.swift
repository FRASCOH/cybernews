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
        self.isBreaking = isBreaking
        self.audioUrl = audioUrl
    }

    public var formattedRelativeTime: String {
        guard let publishedAt = publishedAt else { return "Oggi" }
        // Se la stringa è già relativa o ISO
        if publishedAt.contains("ago") || publishedAt.contains("fa") {
            return publishedAt
        }
        return "Poco fa"
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
