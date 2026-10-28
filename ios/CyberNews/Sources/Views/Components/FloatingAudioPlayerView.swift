import SwiftUI

public struct FloatingAudioPlayerView: View {
    @ObservedObject private var audioManager = AudioBriefingManager.shared
    public var onArticleTap: ((Article) -> Void)? = nil

    public init(onArticleTap: ((Article) -> Void)? = nil) {
        self.onArticleTap = onArticleTap
    }

    public var body: some View {
        if let article = audioManager.currentArticle {
            HStack(spacing: 12) {
                // Visualizer Animato o Icona
                Button {
                    onArticleTap?(article)
                } label: {
                    HStack(spacing: 8) {
                        // Visualizer ad onde sonore
                        HStack(spacing: 2.5) {
                            ForEach(0..<4) { idx in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(CyberTheme.orangePrimary)
                                    .frame(width: 2.5, height: audioManager.isPlaying ? CGFloat([8, 16, 12, 18][idx]) : 4)
                                    .animation(
                                        audioManager.isPlaying
                                            ? .easeInOut(duration: 0.35).repeatForever().delay(Double(idx) * 0.08)
                                            : .default,
                                        value: audioManager.isPlaying
                                    )
                            }
                        }
                        .frame(width: 18, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                if audioManager.isDailyBriefingMode {
                                    Text(audioManager.playlistProgressText.uppercased())
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.cyanPrimary)
                                    Text("•")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.white.opacity(0.3))
                                }

                                Text(article.sourceName)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)
                            }

                            Text(article.titleIt)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Controlli Traccia
                HStack(spacing: 10) {
                    // Traccia Precedente (se in modalità rassegna)
                    if audioManager.isDailyBriefingMode {
                        Button {
                            HapticManager.shared.impact(.light)
                            audioManager.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(audioManager.hasPrevious ? .white.opacity(0.85) : .white.opacity(0.25))
                        }
                        .disabled(!audioManager.hasPrevious)
                        .buttonStyle(.plain)
                    }

                    // Tasto Play / Pausa
                    Button {
                        HapticManager.shared.impact(.medium)
                        if audioManager.isPlaying {
                            audioManager.pause()
                        } else {
                            audioManager.resume()
                        }
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(CyberTheme.orangePrimary))
                    }
                    .buttonStyle(.plain)

                    // Prossima Traccia (se in modalità rassegna)
                    if audioManager.isDailyBriefingMode {
                        Button {
                            HapticManager.shared.impact(.light)
                            audioManager.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(audioManager.hasNext ? .white.opacity(0.85) : .white.opacity(0.25))
                        }
                        .disabled(!audioManager.hasNext)
                        .buttonStyle(.plain)
                    }

                    // Chiudi / Stop
                    Button {
                        HapticManager.shared.impact(.light)
                        audioManager.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        CyberTheme.orangePrimary.opacity(0.5),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: CyberTheme.orangePrimary.opacity(0.25), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
}
