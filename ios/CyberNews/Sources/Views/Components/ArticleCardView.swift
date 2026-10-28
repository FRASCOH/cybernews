import SwiftUI

public struct ArticleCardView: View {
    public let article: Article
    public var isSaved: Bool = false
    public var isRead: Bool = true
    public var onSaveToggle: (() -> Void)? = nil
    public var onTagTap: ((String) -> Void)? = nil

    public init(
        article: Article,
        isSaved: Bool = false,
        isRead: Bool = true,
        onSaveToggle: (() -> Void)? = nil,
        onTagTap: ((String) -> Void)? = nil
    ) {
        self.article = article
        self.isSaved = isSaved
        self.isRead = isRead
        self.onSaveToggle = onSaveToggle
        self.onTagTap = onTagTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Card: Badge Nuova + Fonte + Data + Badge Rischio
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    if !isRead {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(CyberTheme.orangePrimary)
                                .frame(width: 5, height: 5)
                            Text("NUOVA")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundStyle(CyberTheme.orangePrimary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(CyberTheme.orangePrimary.opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .stroke(CyberTheme.orangePrimary.opacity(0.4), lineWidth: 0.8)
                                )
                        )
                    }

                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(CyberTheme.orangePrimary)

                    Text(article.sourceName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(article.formattedRelativeTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                ThreatBadgeView(level: article.threatLevel, compact: true)
            }

            // Titolo Principale in Italiano
            Text(article.titleIt)
                .font(.system(size: 17, weight: isRead ? .medium : .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Anteprima sintetica estesa (AI) - almeno 3 righe di testo
            if !article.summaryPoints.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(CyberTheme.orangePrimary)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)

                    Text(article.summaryPoints.joined(separator: " "))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(isRead ? 0.72 : 0.88))
                        .lineSpacing(3)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Tags Cliccabili
            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.tags.prefix(4), id: \.self) { tag in
                            Button {
                                HapticManager.shared.impact(.light)
                                onTagTap?(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangeLight)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Footer: Box "Cosa fare" compatto + Tasto Salva
            HStack(alignment: .center, spacing: 10) {
                if let action = article.actionMitigation {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(CyberTheme.orangePrimary)

                        Text(action)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(CyberTheme.orangePrimary.opacity(0.10))
                            .overlay(
                                Capsule()
                                    .stroke(CyberTheme.orangePrimary.opacity(0.25), lineWidth: 1)
                            )
                    )
                }

                Spacer()

                if let onSaveToggle = onSaveToggle {
                    Button {
                        HapticManager.shared.impact(.light)
                        onSaveToggle()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSaved ? CyberTheme.orangePrimary : .white.opacity(0.45))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .glassmorphic(cornerRadius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    !isRead ? CyberTheme.orangePrimary.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}
