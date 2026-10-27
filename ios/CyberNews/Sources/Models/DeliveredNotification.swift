import Foundation

public struct DeliveredNotification: Identifiable, Codable, Hashable {
    public let id: String
    public let articleId: String?
    public let title: String
    public let subtitle: String
    public let body: String
    public let threatLevel: ThreatLevel
    public let timestamp: Date
    public var isRead: Bool

    public init(
        id: String = UUID().uuidString,
        articleId: String? = nil,
        title: String,
        subtitle: String,
        body: String,
        threatLevel: ThreatLevel = .informativo,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.articleId = articleId
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.threatLevel = threatLevel
        self.timestamp = timestamp
        self.isRead = isRead
    }

    public var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
