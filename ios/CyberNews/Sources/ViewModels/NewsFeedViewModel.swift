import SwiftUI
import Combine

@MainActor
public final class NewsFeedViewModel: ObservableObject {
    @Published public var articles: [Article] = []
    @Published public var selectedCategory: NewsCategory = .all
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let apiService = NewsAPIService.shared

    public init() {
        Task {
            await loadArticles()
        }
    }

    public var filteredArticles: [Article] {
        var result = articles

        // Filtro per Categoria
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }

        // Filtro per Ricerca Testuale
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { article in
                article.titleIt.lowercased().contains(query) ||
                article.sourceName.lowercased().contains(query) ||
                article.tags.contains(where: { $0.lowercased().contains(query) }) ||
                (article.actionMitigation?.lowercased().contains(query) ?? false)
            }
        }

        return result
    }

    public var breakingArticles: [Article] {
        articles.filter { $0.threatLevel == .critico || ($0.isBreaking ?? false) }
    }

    public func loadArticles() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await apiService.fetchArticles()
            withAnimation(CyberTheme.smoothSpring) {
                self.articles = fetched
            }
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
}
