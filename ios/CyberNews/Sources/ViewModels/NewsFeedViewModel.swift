import SwiftUI
import Combine

@MainActor
public final class NewsFeedViewModel: ObservableObject {
    @Published public var articles: [Article] = []
    @Published public var selectedCategory: NewsCategory = .all
    @Published public var selectedTag: String? = nil
    @Published public var searchText: String = ""
    @Published public var showOnlyUnread: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let apiService = NewsAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // Caricamento istantaneo a latenza 0ms dalla cache
        if let cached = apiService.getCachedArticles(), !cached.isEmpty {
            self.articles = cached
        }

        // Ascolta variazioni dello stato di lettura per aggiornare il filtro reattivamente
        ArticleReadTracker.shared.$readArticleIds
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        Task {
            await loadArticles(forceRefresh: true)
        }
    }

    public var availableTags: [String] {
        var counts: [String: Int] = [:]
        for article in articles {
            for tag in article.tags {
                let clean = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    counts[clean, default: 0] += 1
                }
            }
        }
        // Ordina per frequenza decrescente
        return counts.sorted { $0.value > $1.value }.map { $0.key }
    }

    public var filteredArticles: [Article] {
        var result = articles

        // 1. Filtro per Categoria
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }

        // 2. Filtro per Tag selezionato (es. CVE, Zero-Day, NIS2)
        if let tag = selectedTag {
            result = result.filter { article in
                article.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) ||
                article.titleIt.localizedCaseInsensitiveContains(tag) ||
                (article.actionMitigation?.localizedCaseInsensitiveContains(tag) ?? false)
            }
        }

        // 3. Filtro per Ricerca Testuale
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { article in
                article.titleIt.lowercased().contains(query) ||
                article.sourceName.lowercased().contains(query) ||
                article.tags.contains(where: { $0.lowercased().contains(query) }) ||
                (article.actionMitigation?.lowercased().contains(query) ?? false)
            }
        }

        // 4. Filtro "Solo Non Lette"
        if showOnlyUnread {
            let readIds = ArticleReadTracker.shared.readArticleIds
            result = result.filter { !readIds.contains($0.id) }
        }

        return result
    }

    public var unreadCount: Int {
        let readIds = ArticleReadTracker.shared.readArticleIds
        return articles.filter { !readIds.contains($0.id) }.count
    }

    public var breakingArticles: [Article] {
        articles.filter { $0.threatLevel == .critico || ($0.isBreaking ?? false) }
    }

    public func loadArticles(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await apiService.fetchArticles(forceRefresh: forceRefresh)
            withAnimation(CyberTheme.smoothSpring) {
                self.articles = fetched
            }
            // Notifica per nuovi articoli
            NotificationManager.shared.checkAndNotifyNewArticles(articles: fetched)
        } catch {
            self.errorMessage = "Impossibile aggiornare i dati: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public func selectCategory(_ category: NewsCategory) {
        HapticManager.shared.selection()
        withAnimation(CyberTheme.quickSpring) {
            self.selectedCategory = category
        }
    }

    public func selectTag(_ tag: String?) {
        HapticManager.shared.selection()
        withAnimation(CyberTheme.quickSpring) {
            if self.selectedTag == tag {
                self.selectedTag = nil
            } else {
                self.selectedTag = tag
            }
        }
    }
}
