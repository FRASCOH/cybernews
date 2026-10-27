import SwiftUI
import SafariServices

public struct ArticleDetailView: View {
    public let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false

    public init(article: Article) {
        self.article = article
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Sfondo Minimal Dark
                CyberTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Header: Fonte, Data e Badge Rischio
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 13))
                                        .foregroundStyle(CyberTheme.orangePrimary)

                                    Text(article.sourceName)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }

                                Text(article.publishedAt ?? "Oggi")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Spacer()

                            ThreatBadgeView(level: article.threatLevel)
                        }
                        .padding(.top, 8)

                        // Titolo Completo
                        Text(article.titleIt)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)

                        // Titolo originale in inglese se presente
                        if let orig = article.originalTitle, !orig.isEmpty {
                            Text("Originale: \(orig)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.45))
                                .italic()
                        }

                        // BOX CRITICO: Azione Raccomandata / Mitigazione (Cyber Orange Glow)
                        if let action = article.actionMitigation, !action.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.shield.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(CyberTheme.orangePrimary)

                                    Text("AZIONE RACCOMANDATA")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.orangePrimary)
                                }

                                Text(action)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineSpacing(3)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(CyberTheme.orangePrimary.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(CyberTheme.orangePrimary.opacity(0.5), lineWidth: 1.5)
                                    )
                                    .shadow(color: CyberTheme.orangePrimary.opacity(0.2), radius: 10, x: 0, y: 4)
                            )
                        }

                        // SEZIONE: Analisi AI in 3 Punti Chiave
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15))
                                    .foregroundStyle(CyberTheme.orangePrimary)

                                Text("PUNTI CHIAVE (ANALISI AI)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                            }

                            ForEach(Array(article.summaryPoints.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(CyberTheme.orangePrimary)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(CyberTheme.orangePrimary.opacity(0.15))
                                        )

                                    Text(point)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .lineSpacing(3)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassmorphic(cornerRadius: 18)
                            }
                        }

                        // TAGS TECNICI
                        if !article.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TAG & RIFERIMENTI")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))

                                FlowLayout(spacing: 8) {
                                    ForEach(article.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(CyberTheme.orangeLight)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.06))
                                            )
                                    }
                                }
                            }
                        }

                        // BOTTONE: Apri Fonte Ufficiale (Safari In-App)
                        Button {
                            HapticManager.shared.impact(.medium)
                            showSafari = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 16))

                                Text("Consulta Bollettino / Fonte Ufficiale")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(CyberTheme.orangeGradient)
                                    .shadow(color: CyberTheme.orangePrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let url = URL(string: article.sourceUrl) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(CyberTheme.orangePrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = URL(string: article.sourceUrl) {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

// MARK: - Safari View Wrapper
public struct SafariView: UIViewControllerRepresentable {
    public let url: URL

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(CyberTheme.orangePrimary)
        return vc
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - FlowLayout Helper per i Tag
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
            height = max(height, currentY + maxHeightInRow)
        }

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}
