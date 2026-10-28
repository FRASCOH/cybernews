import SwiftUI
import SafariServices
import AVFoundation

public struct ArticleDetailView: View {
    public let article: Article
    public var onTagTap: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    @State private var selectedCVE: CVEItem? = nil
    @ObservedObject private var audioManager = AudioBriefingManager.shared

    public init(article: Article, onTagTap: ((String) -> Void)? = nil) {
        self.article = article
        self.onTagTap = onTagTap
    }

    private var isCurrentArticlePlaying: Bool {
        audioManager.currentArticleId == article.id && audioManager.isPlaying
    }

    private var isCurrentArticlePaused: Bool {
        audioManager.currentArticleId == article.id && audioManager.isPaused
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Sfondo Minimal Dark
                CyberTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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

                        // MARK: - 🎙️ CYBER BRIEFING VOCALE (Audio Neurale)
                        VStack(alignment: .leading, spacing: 12) {
                            // Intestazione con badge stato
                            HStack {
                                HStack(spacing: 7) {
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(CyberTheme.orangePrimary)

                                    Text("CYBER BRIEFING VOCALE")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.orangePrimary)

                                    if article.resolvedAudioUrl != nil {
                                        Text("HD AI")
                                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                                            .foregroundStyle(CyberTheme.cyanPrimary)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(CyberTheme.cyanPrimary.opacity(0.18)))
                                    }
                                }

                                Spacer()

                                if isCurrentArticlePlaying {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(CyberTheme.cyanPrimary)
                                            .frame(width: 6, height: 6)
                                        Text("IN ASCOLTO")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(CyberTheme.cyanPrimary)
                                    }
                                }
                            }

                            // Descrizione
                            Text(article.resolvedAudioUrl != nil
                                 ? "Lettura integrale fluente con voce neurale AI da studio radiofonico."
                                 : "Sintesi vocale del bollettino disponibile anche in modalità offline.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineSpacing(2)

                            // Riga Controlli di Riproduzione
                            HStack(spacing: 10) {
                                // Tasto Principale Play / Pausa
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    if isCurrentArticlePlaying {
                                        audioManager.pause()
                                    } else {
                                        audioManager.play(article: article)
                                    }
                                } label: {
                                    HStack(spacing: 7) {
                                        Image(systemName: isCurrentArticlePlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 13, weight: .bold))

                                        Text(isCurrentArticlePlaying ? "Pausa" : (isCurrentArticlePaused ? "Riprendi" : "Ascolta Notizia"))
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(isCurrentArticlePlaying ? .black : CyberTheme.orangePrimary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(isCurrentArticlePlaying ? CyberTheme.orangePrimary : CyberTheme.orangePrimary.opacity(0.15))
                                            .overlay(Capsule().stroke(CyberTheme.orangePrimary.opacity(0.4), lineWidth: 1))
                                    )
                                }
                                .buttonStyle(.plain)

                                // Selettore Velocità (1x, 1.25x, 1.5x, 2x)
                                Button {
                                    HapticManager.shared.impact(.light)
                                    audioManager.cyclePlaybackRate()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "gauge.with.needle")
                                            .font(.system(size: 11))
                                        Text(audioManager.formattedRate)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary : .white.opacity(0.85))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary.opacity(0.18) : Color.white.opacity(0.08))
                                            .overlay(
                                                Capsule().stroke(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                if isCurrentArticlePlaying || isCurrentArticlePaused {
                                    Button {
                                        HapticManager.shared.impact(.light)
                                        audioManager.stop()
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "stop.fill")
                                                .font(.system(size: 10))
                                            Text("Stop")
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(Capsule().fill(Color.white.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()
                            }
                        }
                        .padding(14)
                        .glassmorphic(cornerRadius: 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isCurrentArticlePlaying ? CyberTheme.orangePrimary.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                        )

                        // BOX CRITICO: Azione Raccomandata / Mitigazione
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

                        // MARK: - 🛡️ SCHEDE RAPIDE CVE (NVD / MITRE)
                        if !article.detectedCVEs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 15))
                                        .foregroundStyle(CyberTheme.threatCritico)

                                    Text("VULNERABILITÀ IDENTIFICATE (\(article.detectedCVEs.count))")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.threatCritico)

                                    Spacer()

                                    Text("NVD / MITRE")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.45))
                                }

                                VStack(spacing: 8) {
                                    ForEach(article.detectedCVEs, id: \.self) { cveId in
                                        Button {
                                            HapticManager.shared.impact(.medium)
                                            selectedCVE = CVEItem(id: cveId)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "exclamationmark.shield.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(CyberTheme.threatCritico)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(cveId)
                                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                        .foregroundStyle(.white)

                                                    Text("Tocca per Scheda Rapida CVSS e Bollettino")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(.white.opacity(0.6))
                                                }

                                                Spacer()

                                                HStack(spacing: 4) {
                                                    Text("Scheda")
                                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 10))
                                                }
                                                .foregroundStyle(CyberTheme.cyanPrimary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(CyberTheme.cyanPrimary.opacity(0.12))
                                                .clipShape(Capsule())
                                            }
                                            .padding(14)
                                            .glassmorphic(cornerRadius: 16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(CyberTheme.threatCritico.opacity(0.35), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
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

                        // MARK: - 🏷️ TAGS & CVE CLICCABILI
                        if !article.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("TAG & RIFERIMENTI (TOCCA PER FILTRARE)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                    Spacer()
                                }

                                FlowLayout(spacing: 8) {
                                    ForEach(article.tags, id: \.self) { tag in
                                        Button {
                                            HapticManager.shared.impact(.light)
                                            audioManager.stop()
                                            dismiss()
                                            onTagTap?(tag)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text("#\(tag)")
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(CyberTheme.orangeLight)
                                                Image(systemName: "arrow.right")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(CyberTheme.orangeLight.opacity(0.6))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.06))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(CyberTheme.orangePrimary.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
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

                                Text("Consulta Bollettino Ufficiale")
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
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        audioManager.stop()
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
            .sheet(item: $selectedCVE) { item in
                CVEQuickSheetView(cveId: item.id)
                    .presentationDetents([.fraction(0.85), .large])
            }
            .onAppear {
                ArticleReadTracker.shared.markAsRead(id: article.id)
            }
            .onDisappear {
                // Ferma l'audio se la vista viene chiusa
                audioManager.stop()
            }
        }
    }
}

// MARK: - CVE Item Helper
public struct CVEItem: Identifiable {
    public let id: String
    public init(id: String) {
        self.id = id
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
