import SwiftUI

public struct TagFilterBar: View {
    public let tags: [String]
    @Binding public var selectedTag: String?
    public let onSelect: (String?) -> Void

    public init(tags: [String], selectedTag: Binding<String?>, onSelect: @escaping (String?) -> Void) {
        self.tags = tags
        self._selectedTag = selectedTag
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let selected = selectedTag {
                    // Tasto rapido per deselezionare il tag attivo
                    Button {
                        HapticManager.shared.impact(.light)
                        onSelect(nil)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Reset: #\(selected)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CyberTheme.orangePrimary)
                                .shadow(color: CyberTheme.orangePrimary.opacity(0.4), radius: 6, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(tags.prefix(15), id: \.self) { tag in
                    let isSelected = selectedTag?.caseInsensitiveCompare(tag) == .orderedSame

                    Button {
                        HapticManager.shared.selection()
                        onSelect(tag)
                    } label: {
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? .black : CyberTheme.orangeLight)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}
