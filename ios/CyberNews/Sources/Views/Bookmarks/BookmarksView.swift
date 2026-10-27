import SwiftUI
import SwiftData

public struct BookmarksView: View {
    @Query(sort: \SavedArticle.savedAt, order: .reverse) private var savedArticles: [SavedArticle]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedArticle: Article? = nil

    public init() {}

    public var body: some View {
        ZStack {
            CyberTheme.backgroundDark
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Salvati & Offline")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Consultabili in qualsiasi momento senza connessione")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if savedArticles.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()

                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 46))
                            .foregroundStyle(CyberTheme.orangePrimary.opacity(0.4))

                        Text("Nessun articolo salvato")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Fai tap sull'icona del segnalibro per salvare gli articoli critici da leggere offline.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(savedArticles) { saved in
                                let article = Article(
                                    id: saved.id,
                                    urlHash: saved.id,
                                    titleIt: saved.titleIt,
                                    originalTitle: saved.originalTitle,
                                    summaryPoints: saved.summaryPoints,
                                    actionMitigation: saved.actionMitigation,
                                    threatLevel: saved.threatLevel,
                                    category: saved.category,
                                    sourceName: saved.sourceName,
                                    sourceUrl: saved.sourceUrl,
                                    publishedAt: saved.publishedAt
                                )

                                ArticleCardView(
                                    article: article,
                                    isSaved: true,
                                    onSaveToggle: {
                                        modelContext.delete(saved)
                                    }
                                )
                                .onTapGesture {
                                    HapticManager.shared.impact(.light)
                                    selectedArticle = article
                                }
                            }

                            Color.clear.frame(height: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }
}
