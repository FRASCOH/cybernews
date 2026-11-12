import SwiftUI

public struct ArticleCardView: View {
    public let article: Article
    public var isSaved: Bool = false
    public var isRead: Bool = true
    public var onSelect: (() -> Void)? = nil
    public var onReadToggle: (() -> Void)? = nil
    public var onSaveToggle: (() -> Void)? = nil
    public var onTagTap: ((String) -> Void)? = nil

    public init(
        article: Article,
        isSaved: Bool = false,
        isRead: Bool = true,
        onSelect: (() -> Void)? = nil,
        onReadToggle: (() -> Void)? = nil,
        onSaveToggle: (() -> Void)? = nil,
        onTagTap: ((String) -> Void)? = nil
    ) {
        self.article = article
        self.isSaved = isSaved
        self.isRead = isRead
        self.onSelect = onSelect
        self.onReadToggle = onReadToggle
        self.onSaveToggle = onSaveToggle
        self.onTagTap = onTagTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Card: Fonte + Data + Badge Rischio
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(CyberTheme.cyanPrimary)
                        .frame(width: 7, height: 7)
                        .shadow(color: CyberTheme.cyanPrimary.opacity(0.8), radius: 3)
                        .opacity(isRead ? 0 : 1)

                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(isRead ? CyberTheme.orangePrimary : CyberTheme.cyanPrimary)

                    Text(article.primarySourceName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if article.additionalSourcesCount > 0 {
                        Text("+\(article.additionalSourcesCount)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(CyberTheme.cyanPrimary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(CyberTheme.cyanPrimary.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(article.formattedRelativeTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Spacer(minLength: 6)

                HStack(spacing: 6) {
                    if let firstCVE = article.detectedCVEs.first {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 8))
                            Text(firstCVE)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(CyberTheme.threatCritico)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(CyberTheme.threatCritico.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    ThreatBadgeView(level: article.threatLevel, compact: true)
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            // Titolo Principale in Italiano a tutta larghezza (peso font fisso per evitare reflow del testo)
            Text(article.titleIt)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(isRead ? .white.opacity(0.72) : .white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Anteprima sintetica estesa (AI) - almeno 3 righe piene
            if !article.summaryPoints.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(isRead ? CyberTheme.orangePrimary : CyberTheme.cyanPrimary)
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
                                onTagTap?(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isRead ? CyberTheme.orangeLight : CyberTheme.cyanLight)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    HapticManager.shared.impact(.light)
                                    onTagTap?(tag)
                                }
                            )
                        }
                    }
                }
            }

            // Footer: Box "Cosa fare" compatto + Tasto Segna come letto + Tasto Salva
            HStack(alignment: .center, spacing: 8) {
                if let action = article.actionMitigation {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(isRead ? CyberTheme.orangePrimary : CyberTheme.cyanPrimary)

                        Text(action)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((isRead ? CyberTheme.orangePrimary : CyberTheme.cyanPrimary).opacity(0.10))
                            .overlay(
                                Capsule()
                                    .stroke((isRead ? CyberTheme.orangePrimary : CyberTheme.cyanPrimary).opacity(0.25), lineWidth: 1)
                            )
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    // Tasto Segna come letto / Non letto (dimensione fissa per impedire lo spostamento del footer)
                    if let onReadToggle = onReadToggle {
                        Button {
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isRead ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isRead ? "Letta" : "Segna letta")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(isRead ? .white.opacity(0.55) : CyberTheme.cyanPrimary)
                            .frame(width: 94, height: 28)
                            .background(
                                Capsule()
                                    .fill(isRead ? Color.white.opacity(0.05) : CyberTheme.cyanPrimary.opacity(0.14))
                                    .overlay(
                                        Capsule()
                                            .stroke(isRead ? Color.white.opacity(0.08) : CyberTheme.cyanPrimary.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        .highPriorityGesture(
                            TapGesture().onEnded {
                                HapticManager.shared.impact(.medium)
                                onReadToggle()
                            }
                        )
                    }

                    // Tasto Segnalibro
                    if let onSaveToggle = onSaveToggle {
                        Button {
                        } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSaved ? CyberTheme.orangePrimary : .white.opacity(0.45))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            Circle()
                                                .stroke(isSaved ? CyberTheme.orangePrimary.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        .highPriorityGesture(
                            TapGesture().onEnded {
                                HapticManager.shared.impact(.light)
                                onSaveToggle()
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
        .glassmorphic(cornerRadius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    !isRead ? CyberTheme.unreadCardGradient : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: !isRead ? 1.6 : 1.0
                )
        )
        .shadow(
            color: !isRead ? CyberTheme.cyanGlow : Color.clear,
            radius: 10,
            x: 0,
            y: 3
        )
    }
}
