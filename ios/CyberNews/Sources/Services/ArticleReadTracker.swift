import Foundation
import SwiftUI
import Combine

@MainActor
public final class ArticleReadTracker: ObservableObject {
    public static let shared = ArticleReadTracker()

    private let storageKey = "cybernews_read_article_ids"

    @Published public private(set) var readArticleIds: Set<String> = []

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        self.readArticleIds = Set(saved)
    }

    public func isRead(id: String) -> Bool {
        readArticleIds.contains(id)
    }

    public func markAsRead(id: String) {
        guard !readArticleIds.contains(id) else { return }
        readArticleIds.insert(id)
        persist()
    }

    public func markAllAsRead(articles: [Article]) {
        for a in articles {
            readArticleIds.insert(a.id)
        }
        persist()
    }

    public func toggleRead(id: String) {
        if readArticleIds.contains(id) {
            readArticleIds.remove(id)
        } else {
            readArticleIds.insert(id)
        }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(readArticleIds), forKey: storageKey)
    }
}
