import SwiftUI
import SwiftData

public struct HomeFeedView: View {
    @ObservedObject public var viewModel: NewsFeedViewModel
    @Query private var savedArticles: [SavedArticle]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedArticleForDetail: Article? = nil
    @State private var isSearchVisible: Bool = false

    public init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Sfondo Minimal Dark
            CyberTheme.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header: Logo CyberNews + Search Icon
                HStack {
                    CyberLogoView()

                    Spacer()

                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(CyberTheme.quickSpring) {
                            isSearchVisible.toggle()
                            if !isSearchVisible {
                                viewModel.searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: isSearchVisible ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isSearchVisible ? CyberTheme.orangePrimary : .white.opacity(0.8))
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Search Bar espandibile con Glassmorphism
                if isSearchVisible {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(CyberTheme.orangePrimary)

                        TextField("Cerca CVE, NIS2, ACN o software...", text: $viewModel.searchText)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()

                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassmorphic(cornerRadius: 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Barra Categorie a Scorrimento
                CategoryPillBar(
                    selectedCategory: $viewModel.selectedCategory,
                    onSelect: { category in
                        viewModel.selectCategory(category)
                    }
                )

                // Lista Notizie
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Allarmi Critici Breaking News Banner (se ce ne sono)
                        if let topBreaking = viewModel.breakingArticles.first, viewModel.selectedCategory == .all && viewModel.searchText.isEmpty {
                            Button {
                                HapticManager.shared.impact(.medium)
                                selectedArticleForDetail = topBreaking
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(CyberTheme.threatCritico)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ALLARME CRITICO IN CORSO")
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                            .foregroundStyle(CyberTheme.threatCritico)

                                        Text(topBreaking.titleIt)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(CyberTheme.threatCritico.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(CyberTheme.threatCritico.opacity(0.4), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }

                        // Lista Card Notizie
                        ForEach(viewModel.filteredArticles) { article in
                            let isArticleSaved = savedArticles.contains(where: { $0.id == article.id })

                            ArticleCardView(
                                article: article,
                                isSaved: isArticleSaved,
                                onSaveToggle: {
                                    toggleSaveArticle(article)
                                }
                            )
                            .onTapGesture {
                                HapticManager.shared.impact(.light)
                                selectedArticleForDetail = article
                            }
                        }

                        // Spaziatura per non coprire l'ultima card con la tab bar fluttuante
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .refreshable {
                    HapticManager.shared.impact(.light)
                    await viewModel.loadArticles()
                }
            }
        }
        .sheet(item: $selectedArticleForDetail) { article in
            ArticleDetailView(article: article)
        }
    }

    private func toggleSaveArticle(_ article: Article) {
        if let existing = savedArticles.first(where: { $0.id == article.id }) {
            modelContext.delete(existing)
        } else {
            let newSaved = SavedArticle(article: article)
            modelContext.insert(newSaved)
        }
    }
}
