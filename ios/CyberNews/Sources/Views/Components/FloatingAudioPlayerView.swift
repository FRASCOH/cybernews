import SwiftUI

public struct FloatingAudioPlayerView: View {
    @ObservedObject private var audioManager = AudioBriefingManager.shared
    public var onArticleTap: ((Article) -> Void)? = nil

    public init(onArticleTap: ((Article) -> Void)? = nil) {
        self.onArticleTap = onArticleTap
    }

    public var body: some View {
        if let article = audioManager.currentArticle {
            HStack(spacing: 10) {
                // Tasto principale per aprire il dettaglio della notizia in riproduzione
                Button {
                    onArticleTap?(article)
                } label: {
                    HStack(spacing: 10) {
                        // Badge / Visualizer animato ad onde
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(CyberTheme.surfaceCard)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(CyberTheme.orangePrimary.opacity(0.35), lineWidth: 1)
                                )

                            if audioManager.isPlaying {
                                HStack(spacing: 2) {
                                    ForEach(0..<4) { idx in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(CyberTheme.orangePrimary)
                                            .frame(width: 2.5, height: CGFloat([8, 16, 12, 18][idx]))
                                            .animation(
                                                .easeInOut(duration: 0.35).repeatForever().delay(Double(idx) * 0.08),
                                                value: audioManager.isPlaying
                                            )
                                    }
                                }
                            } else {
                                Image(systemName: "waveform")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(CyberTheme.orangePrimary.opacity(0.8))
                            }
                        }

                        // Testi Notizia (Metadati + Titolo)
                        VStack(alignment: .leading, spacing: 2) {
                            // Riga superiore: Badge Rassegna + Fonte + Tag AI
                            HStack(spacing: 5) {
                                if audioManager.isDailyBriefingMode {
                                    Text("\(audioManager.currentIndex + 1)/\(audioManager.playlist.count)")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.cyanPrimary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(CyberTheme.cyanPrimary.opacity(0.18)))
                                }

                                Text(article.sourceName)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)
                                    .lineLimit(1)

                                if audioManager.isNeuralVoice {
                                    HStack(spacing: 2) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 7))
                                        Text("AI")
                                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(CyberTheme.cyanPrimary.opacity(0.18)))
                                    .foregroundStyle(CyberTheme.cyanPrimary)
                                }
                            }

                            // Titolo notizia troncato elegantemente senza sovrapposizioni
                            Text(article.titleIt)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
                .layoutPriority(1)

                // Controlli Media
                HStack(spacing: 6) {
                    // Selettore Velocità (1x, 1.25x, 1.5x, 2x)
                    Button {
                        HapticManager.shared.impact(.light)
                        audioManager.cyclePlaybackRate()
                    } label: {
                        Text(audioManager.formattedRate)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary : .white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary.opacity(0.18) : Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule().stroke(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    // Traccia Precedente (se in modalità rassegna)
                    if audioManager.isDailyBriefingMode {
                        Button {
                            HapticManager.shared.impact(.light)
                            audioManager.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(audioManager.hasPrevious ? .white.opacity(0.9) : .white.opacity(0.25))
                                .frame(width: 28, height: 28)
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
                            .font(.system(size: 13, weight: .bold))
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
                                .font(.system(size: 11))
                                .foregroundStyle(audioManager.hasNext ? .white.opacity(0.9) : .white.opacity(0.25))
                                .frame(width: 28, height: 28)
                        }
                        .disabled(!audioManager.hasNext)
                        .buttonStyle(.plain)
                    }

                    // Tasto Chiudi / Stop
                    Button {
                        HapticManager.shared.impact(.light)
                        audioManager.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        CyberTheme.orangePrimary.opacity(0.6),
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 14)
        }
    }
}
