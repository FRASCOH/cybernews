import Foundation
import SwiftData

@Model
public final class SavedArticle {
    @Attribute(.unique) public var id: String
    public var titleIt: String
    public var originalTitle: String?
    public var summaryPointsData: Data
    public var actionMitigation: String?
    public var threatLevelRaw: String
    public var categoryRaw: String
    public var sourceName: String
    public var sourceUrl: String
    public var publishedAt: String?
    public var savedAt: Date

    public init(article: Article) {
        self.id = article.id
        self.titleIt = article.titleIt
        self.originalTitle = article.originalTitle
        self.summaryPointsData = (try? JSONEncoder().encode(article.summaryPoints)) ?? Data()
        self.actionMitigation = article.actionMitigation
        self.threatLevelRaw = article.threatLevel.rawValue
        self.categoryRaw = article.category.rawValue
        self.sourceName = article.sourceName
        self.sourceUrl = article.sourceUrl
        self.publishedAt = article.publishedAt
        self.savedAt = Date()
    }

    public var summaryPoints: [String] {
        (try? JSONDecoder().decode([String].self, from: summaryPointsData)) ?? []
    }

    public var threatLevel: ThreatLevel {
        ThreatLevel(rawValue: threatLevelRaw) ?? .medio
    }

    public var category: NewsCategory {
        NewsCategory(rawValue: categoryRaw) ?? .all
    }
}
