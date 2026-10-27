import SwiftUI

public struct CategoryPillBar: View {
    @Binding public var selectedCategory: NewsCategory
    public let onSelect: (NewsCategory) -> Void

    public init(selectedCategory: Binding<NewsCategory>, onSelect: @escaping (NewsCategory) -> Void) {
        self._selectedCategory = selectedCategory
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NewsCategory.allCases) { category in
                    let isSelected = category == selectedCategory

                    Button {
                        onSelect(category)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11, weight: .semibold))

                            Text(category.displayName)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            isSelected ? CyberTheme.orangeLight.opacity(0.8) : Color.white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: isSelected ? CyberTheme.orangePrimary.opacity(0.35) : Color.clear,
                                    radius: 8,
                                    x: 0,
                                    y: 3
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(CyberTheme.quickSpring, value: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}
