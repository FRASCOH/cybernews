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

    /// Determina se la notizia risale a più di 3 mesi fa (90 giorni) ed è stata archiviata dal feed pubblico
    public var isOlderThanThreeMonths: Bool {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        if savedAt < ninetyDaysAgo {
            return true
        }
        if let pub = publishedAt?.lowercased() {
            if pub.contains("3 mesi") || pub.contains("4 mesi") || pub.contains("5 mesi") ||
               pub.contains("6 mesi") || pub.contains("anno") || pub.contains("anni") {
                return true
            }
        }
        return false
    }
}
