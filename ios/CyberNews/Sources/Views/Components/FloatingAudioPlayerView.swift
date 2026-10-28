import SwiftUI

public struct FloatingAudioPlayerView: View {
    @ObservedObject private var audioManager = AudioBriefingManager.shared
    public var onArticleTap: ((Article) -> Void)? = nil

    public init(onArticleTap: ((Article) -> Void)? = nil) {
        self.onArticleTap = onArticleTap
    }

    public var body: some View {
        if let article = audioManager.currentArticle {
            HStack(spacing: 8) {
                // Sezione Sinistra: Visualizer + Testi Notizia (Tocco apre la notizia)
                HStack(spacing: 9) {
                    // Badge Visualizer con onde animate
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CyberTheme.surfaceCard)
                            .frame(width: 36, height: 36)
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

                    // Testi: Fonte e Rassegna sopra, Titolo sotto
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
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

                        Text(article.titleIt)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onArticleTap?(article)
                }

                // Sezione Destra: Controlli Media con Target di Tocco Ampi e Indipendenti
                HStack(spacing: 6) {
                    // 1. Tasto Velocità di Riproduzione (1x, 1.25x, 1.5x, 2x)
                    Button {
                        HapticManager.shared.impact(.light)
                        audioManager.cyclePlaybackRate()
                    } label: {
                        Text(audioManager.formattedRate)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary : .white)
                            .frame(width: 36, height: 28)
                            .background(
                                Capsule()
                                    .fill(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary.opacity(0.22) : Color.white.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(audioManager.playbackRate > 1.0 ? CyberTheme.cyanPrimary : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    // 2. Tasto Traccia Successiva (se in rassegna continua)
                    if audioManager.isDailyBriefingMode {
                        Button {
                            HapticManager.shared.impact(.light)
                            audioManager.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(audioManager.hasNext ? .white : .white.opacity(0.25))
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .disabled(!audioManager.hasNext)
                        .buttonStyle(.plain)
                    }

                    // 3. Tasto Play / Pausa
                    Button {
                        HapticManager.shared.impact(.medium)
                        if audioManager.isPlaying {
                            audioManager.pause()
                        } else {
                            audioManager.resume()
                        }
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(CyberTheme.orangePrimary))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // 4. Tasto Chiudi / Stop
                    Button {
                        HapticManager.shared.impact(.light)
                        audioManager.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.96))
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
                    .shadow(color: Color.black.opacity(0.55), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 14)
        }
    }
}
