import SwiftUI

public enum CyberTab: Int, CaseIterable {
    case feed = 0
    case governance = 1
    case bookmarks = 2
    case settings = 3

    var title: String {
        switch self {
        case .feed:       return "Feed"
        case .governance: return "Governance"
        case .bookmarks:  return "Salvati"
        case .settings:   return "Impostazioni"
        }
    }

    var iconName: String {
        switch self {
        case .feed:       return "newspaper.fill"
        case .governance: return "building.columns.fill"
        case .bookmarks:  return "bookmark.fill"
        case .settings:   return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @StateObject private var viewModel = NewsFeedViewModel()
    @State private var selectedTab: CyberTab = .feed

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Contenuto delle Tab
            Group {
                switch selectedTab {
                case .feed:
                    HomeFeedView(viewModel: viewModel)
                case .governance:
                    GovernanceView(viewModel: viewModel)
                case .bookmarks:
                    BookmarksView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Glassmorphic Tab Bar
            HStack(spacing: 0) {
                ForEach(CyberTab.allCases, id: \.self) { tab in
                    let isSelected = tab == selectedTab

                    Button {
                        HapticManager.shared.selection()
                        withAnimation(CyberTheme.quickSpring) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? CyberTheme.orangePrimary : .white.opacity(0.45))
                                .scaleEffect(isSelected ? 1.12 : 1.0)

                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? CyberTheme.orangePrimary : .white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.20),
                                        Color.white.opacity(0.05),
                                        CyberTheme.orangePrimary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .ignoresSafeArea(.keyboard)
    }
}
