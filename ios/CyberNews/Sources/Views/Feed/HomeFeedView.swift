import SwiftUI
import SwiftData

public struct HomeFeedView: View {
    @ObservedObject public var viewModel: NewsFeedViewModel
    @ObservedObject private var readTracker = ArticleReadTracker.shared
    @Query private var savedArticles: [SavedArticle]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

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
                // Top Header: Logo CyberNews + Filtro Non Lette + Search Icon
                HStack(spacing: 8) {
                    CyberLogoView()

                    Spacer()

                    // Tasto Filtro Rapido "Solo Non Lette"
                    Button {
                        HapticManager.shared.impact(.medium)
                        withAnimation(CyberTheme.quickSpring) {
                            viewModel.showOnlyUnread.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.showOnlyUnread ? "eye.fill" : "eye")
                                .font(.system(size: 13, weight: .bold))

                            if viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(viewModel.showOnlyUnread ? Color.black.opacity(0.35) : CyberTheme.cyanPrimary)
                                    .foregroundStyle(viewModel.showOnlyUnread ? CyberTheme.cyanPrimary : .black)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundStyle(viewModel.showOnlyUnread ? CyberTheme.cyanPrimary : .white.opacity(0.75))
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 19, style: .continuous)
                                .fill(viewModel.showOnlyUnread ? CyberTheme.cyanPrimary.opacity(0.18) : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                                        .stroke(viewModel.showOnlyUnread ? CyberTheme.cyanPrimary.opacity(0.55) : Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Tasto Ricerca
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
                            .font(.system(size: 15, weight: .bold))
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

                // 🏷️ Barra Tag & CVE Cliccabili
                if !viewModel.availableTags.isEmpty {
                    TagFilterBar(
                        tags: viewModel.availableTags,
                        selectedTag: $viewModel.selectedTag,
                        onSelect: { tag in
                            viewModel.selectTag(tag)
                        }
                    )
                    .padding(.bottom, 4)
                }

                // Lista Notizie
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Allarmi Critici Breaking News Banner
                        if let topBreaking = viewModel.breakingArticles.first,
                           viewModel.selectedCategory == .all && viewModel.searchText.isEmpty && viewModel.selectedTag == nil {
                            Button {
                                HapticManager.shared.impact(.medium)
                                readTracker.markAsRead(id: topBreaking.id)
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

                        // Badge indicatore filtro tag attivo
                        if let activeTag = viewModel.selectedTag {
                            HStack {
                                Text("Filtro attivo: ")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.6))

                                Text("#\(activeTag)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)

                                Text("(\(viewModel.filteredArticles.count) risultati)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.4))

                                Spacer()

                                Button {
                                    viewModel.selectTag(nil)
                                } label: {
                                    Text("Rimuovi")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(CyberTheme.orangePrimary)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                        }

                        // Badge indicatore filtro "Solo Non Lette" attivo
                        if viewModel.showOnlyUnread {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 11))
                                    Text("FILTRO: SOLO NOTIZIE NON LETTE")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(CyberTheme.cyanPrimary)

                                Spacer()

                                if viewModel.unreadCount > 0 {
                                    Button {
                                        HapticManager.shared.notification(.success)
                                        readTracker.markAllAsRead(articles: viewModel.articles)
                                    } label: {
                                        Text("Segna tutte lette")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(CyberTheme.cyanPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                        }

                        // Stato vuoto se non ci sono notizie per i filtri applicati
                        if viewModel.filteredArticles.isEmpty {
                            if viewModel.showOnlyUnread {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(CyberTheme.cyanPrimary)

                                    Text("Tutte le notizie sono state lette!")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("Sei al passo con tutte le ultime minacce e aggiornamenti.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)

                                    Button {
                                        HapticManager.shared.impact(.light)
                                        withAnimation {
                                            viewModel.showOnlyUnread = false
                                        }
                                    } label: {
                                        Text("Mostra tutte le notizie")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(CyberTheme.cyanPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(CyberTheme.cyanPrimary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white.opacity(0.3))

                                    Text("Nessuna notizia trovata")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                            }
                        }

                        // Lista Card Notizie
                        ForEach(viewModel.filteredArticles) { article in
                            let isArticleSaved = savedArticles.contains(where: { $0.id == article.id })
                            let isArticleRead = readTracker.isRead(id: article.id)

                            ArticleCardView(
                                article: article,
                                isSaved: isArticleSaved,
                                isRead: isArticleRead,
                                onSaveToggle: {
                                    toggleSaveArticle(article)
                                },
                                onTagTap: { tag in
                                    viewModel.selectTag(tag)
                                }
                            )
                            .onTapGesture {
                                HapticManager.shared.impact(.light)
                                readTracker.markAsRead(id: article.id)
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
                    await viewModel.loadArticles(forceRefresh: true)
                }
            }
        }
        .sheet(item: $selectedArticleForDetail) { article in
            ArticleDetailView(article: article) { tag in
                viewModel.selectTag(tag)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await viewModel.loadArticles(forceRefresh: true)
                }
            }
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
