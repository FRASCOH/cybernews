import SwiftUI

public struct GovernanceView: View {
    @ObservedObject public var viewModel: NewsFeedViewModel
    @State private var selectedFilter: String = "Tutti"
    @State private var selectedArticle: Article? = nil

    private let filters = ["Tutti", "NIS2", "Golden Power", "ACN", "ISO 27001", "DORA"]

    public init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
    }

    public var governanceArticles: [Article] {
        let base = viewModel.articles.filter {
            $0.category == .nis2GoldenPower || $0.category == .complianceIso ||
            $0.tags.contains(where: { ["ACN", "NIS2", "Golden Power", "ISO 27001", "DORA"].contains($0) })
        }

        if selectedFilter == "Tutti" {
            return base
        }
        return base.filter { article in
            article.tags.contains(where: { $0.localizedCaseInsensitiveContains(selectedFilter) }) ||
            article.titleIt.localizedCaseInsensitiveContains(selectedFilter)
        }
    }

    public var body: some View {
        ZStack {
            CyberTheme.backgroundDark
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Governance & Normative")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("ACN • NIS2 • Golden Power • ISO 27001")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CyberTheme.orangePrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Filtro Rapido
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { item in
                            let isSelected = item == selectedFilter
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(CyberTheme.quickSpring) {
                                    selectedFilter = item
                                }
                            } label: {
                                Text(item)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.06))
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? CyberTheme.orangeLight : Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Lista Notizie Governance
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if governanceArticles.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(CyberTheme.orangePrimary.opacity(0.5))
                                    .padding(.top, 40)

                                Text("Nessun aggiornamento per questo filtro")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        } else {
                            ForEach(governanceArticles) { article in
                                ArticleCardView(article: article)
                                    .onTapGesture {
                                        HapticManager.shared.impact(.light)
                                        selectedArticle = article
                                    }
                            }
                        }

                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }
}
