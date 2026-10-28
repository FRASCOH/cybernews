import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
public final class AudioBriefingManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = AudioBriefingManager()

    private let synthesizer = AVSpeechSynthesizer()

    @Published public var isPlaying: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var currentArticleId: String? = nil
    @Published public var currentArticle: Article? = nil

    // MARK: - Playlist / Rassegna Continua
    @Published public var playlist: [Article] = []
    @Published public var currentIndex: Int = 0
    @Published public var isDailyBriefingMode: Bool = false

    public var hasNext: Bool {
        currentIndex + 1 < playlist.count
    }

    public var hasPrevious: Bool {
        currentIndex > 0
    }

    public var playlistProgressText: String {
        guard !playlist.isEmpty else { return "" }
        return "Notizia \(currentIndex + 1) di \(playlist.count)"
    }

    override private init() {
        super.init()
        synthesizer.delegate = self
        setupRemoteCommandCenter()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Errore configurazione AVAudioSession: \(error)")
        }
    }

    // MARK: - Riproduzione Rassegna Continua
    public func startDailyBriefing(articles: [Article], startIndex: Int = 0) {
        guard !articles.isEmpty else { return }
        stop()

        self.playlist = articles
        self.currentIndex = max(0, min(startIndex, articles.count - 1))
        self.isDailyBriefingMode = true

        playCurrentQueueItem(isIntro: startIndex == 0)
    }

    // MARK: - Riproduzione Singolo Articolo
    public func play(article: Article) {
        // Se era in pausa per questo articolo, riprendi
        if currentArticleId == article.id && isPaused {
            resume()
            return
        }

        stop()
        self.playlist = [article]
        self.currentIndex = 0
        self.isDailyBriefingMode = false

        playCurrentQueueItem(isIntro: false)
    }

    private func playCurrentQueueItem(isIntro: Bool) {
        guard currentIndex < playlist.count else {
            stop()
            return
        }

        configureAudioSession()
        let article = playlist[currentIndex]
        currentArticle = article
        currentArticleId = article.id

        // Segna automaticamente come letto
        ArticleReadTracker.shared.markAsRead(id: article.id)

        // Costruisci il testo parlato
        var speechText = ""
        if isIntro {
            speechText += "Benvenuto alla rassegna vocale di CyberNews. Ecco le notizie di sicurezza di oggi. "
        } else if isDailyBriefingMode {
            speechText += "Prossima notizia. "
        }

        speechText += "Fonte: \(article.sourceName). Livello di rischio: \(article.threatLevel.rawValue). "
        speechText += "\(article.titleIt). "

        if !article.summaryPoints.isEmpty {
            speechText += "Sintesi: "
            for (idx, point) in article.summaryPoints.enumerated() {
                speechText += "Punto \(idx + 1): \(point). "
            }
        }

        if let action = article.actionMitigation, !action.isEmpty {
            speechText += "Azione consigliata: \(action). "
        }

        let utterance = AVSpeechUtterance(string: speechText)
        if let italianVoice = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = italianVoice
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.3

        isPlaying = true
        isPaused = false

        updateNowPlayingInfo(article: article)
        synthesizer.speak(utterance)
    }

    public func next() {
        guard hasNext else {
            speakOutroAndStop()
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        currentIndex += 1
        playCurrentQueueItem(isIntro: false)
    }

    public func previous() {
        guard hasPrevious else { return }
        synthesizer.stopSpeaking(at: .immediate)
        currentIndex -= 1
        playCurrentQueueItem(isIntro: false)
    }

    public func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPlaying = false
            isPaused = true
            updatePlaybackState(isPlaying: false)
        }
    }

    public func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
            isPaused = false
            updatePlaybackState(isPlaying: true)
        }
    }

    public func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
        currentArticleId = nil
        currentArticle = nil
        isDailyBriefingMode = false
        clearNowPlayingInfo()
    }

    private func speakOutroAndStop() {
        let outroText = "Rassegna vocale conclusa. Sei aggiornato su tutte le principali minacce e normative."
        let utterance = AVSpeechUtterance(string: outroText)
        if let italianVoice = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = italianVoice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        isPlaying = true
        isPaused = false
        synthesizer.speak(utterance)
    }

    // MARK: - NowPlaying & Controlli Blocco Schermo / AirPods
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.resume()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.pause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.next()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.previous()
            }
            return .success
        }
    }

    private func updateNowPlayingInfo(article: Article) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = article.titleIt
        nowPlayingInfo[MPMediaItemPropertyArtist] = "CyberNews • \(article.sourceName)"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = isDailyBriefingMode ? "Rassegna del Giorno (\(playlistProgressText))" : "Cyber Briefing"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updatePlaybackState(isPlaying: Bool) {
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if self.isDailyBriefingMode {
                if self.hasNext {
                    self.next()
                } else {
                    self.stop()
                }
            } else {
                self.stop()
            }
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.stop()
        }
    }
}
