import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
public final class AudioBriefingManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = AudioBriefingManager()

    // Motore Neurale Edge TTS via AVPlayer & Fallback su dispositivo
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVPlayer?
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemDidPlayToEndObserver: NSObjectProtocol?
    private var playerItemFailedObserver: NSObjectProtocol?

    @Published public var isPlaying: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var isNeuralVoice: Bool = false
    @Published public var currentArticleId: String? = nil
    @Published public var currentArticle: Article? = nil

    // MARK: - Velocità di Riproduzione (1.0x, 1.25x, 1.5x, 2.0x)
    @Published public var playbackRate: Float = 1.0

    public var formattedRate: String {
        if playbackRate == 1.0 {
            return "1x"
        } else if playbackRate == 1.25 {
            return "1.25x"
        } else if playbackRate == 1.5 {
            return "1.5x"
        } else if playbackRate == 2.0 {
            return "2x"
        } else {
            return String(format: "%.1fx", playbackRate)
        }
    }

    public func cyclePlaybackRate() {
        let speeds: [Float] = [1.0, 1.25, 1.5, 2.0]
        if let idx = speeds.firstIndex(where: { abs($0 - playbackRate) < 0.05 }), idx + 1 < speeds.count {
            setPlaybackRate(speeds[idx + 1])
        } else {
            setPlaybackRate(1.0)
        }
    }

    public func setPlaybackRate(_ rate: Float) {
        self.playbackRate = rate
        UserDefaults.standard.set(rate, forKey: "cybernews_audio_rate")
        if isPlaying && isNeuralVoice {
            player?.rate = rate
        }
        updatePlaybackState(isPlaying: isPlaying)
    }

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
        let savedRate = UserDefaults.standard.float(forKey: "cybernews_audio_rate")
        if savedRate >= 1.0 && savedRate <= 2.0 {
            self.playbackRate = savedRate
        }
        synthesizer.delegate = self
        setupRemoteCommandCenter()
    }

    private func configureAudioSession() {
        // Esegue la configurazione audio fuori dal Main Thread per evitare Hang Risk
        Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true)
            } catch {
                print("⚠️ Errore configurazione AVAudioSession: \(error)")
            }
        }
    }

    private func cleanupPlayer() {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil

        if let observer = playerItemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemDidPlayToEndObserver = nil
        }
        if let observer = playerItemFailedObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemFailedObserver = nil
        }
        player?.pause()
        player = nil
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

        // Controllo se è disponibile l'audio neurale studio ad alta definizione
        if let audioUrlString = article.resolvedAudioUrl,
           let streamURL = URL(string: audioUrlString),
           !audioUrlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            playNeuralAudio(url: streamURL, article: article)
            return
        }

        // Fallback su sintetizzatore on-device (se offline o audioUrl non disponibile)
        playSynthesizerAudio(article: article, isIntro: isIntro)
    }

    // MARK: - Riproduzione Streaming Neurale (Edge TTS via AVPlayer)
    private func playNeuralAudio(url: URL, article: Article) {
        cleanupPlayer()
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        print("🎙️ [AudioBriefingManager] Avvio streaming neurale HD per: \(article.titleIt)")
        print("     URL: \(url.absoluteString)")

        let playerItem = AVPlayerItem(url: url)
        playerItem.audioTimePitchAlgorithm = .timeDomain
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer

        // Monitoraggio stato per gestione errori o avvio fluido
        playerStatusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch item.status {
                case .failed:
                    print("⚠️ [AudioBriefingManager] Fallito caricamento stream (\(String(describing: item.error))), fallback su sintesi locale")
                    self.cleanupPlayer()
                    self.playSynthesizerAudio(article: article, isIntro: false)
                case .readyToPlay:
                    print("✅ [AudioBriefingManager] Stream neurale pronto, avvio riproduzione a \(self.playbackRate)x")
                    self.player?.playImmediately(atRate: self.playbackRate)
                default:
                    break
                }
            }
        }

        // Avanzamento automatico al termine dell'audio
        playerItemDidPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isDailyBriefingMode {
                    if self.hasNext {
                        self.next()
                    } else {
                        self.speakOutroAndStop()
                    }
                } else {
                    self.stop()
                }
            }
        }

        // Fallback di resilienza: se il caricamento da rete fallisce, usa la voce di sistema
        playerItemFailedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("⚠️ Stream audio neurale fallito, fallback automatico a voce su dispositivo")
                self.cleanupPlayer()
                self.playSynthesizerAudio(article: article, isIntro: false)
            }
        }

        isPlaying = true
        isPaused = false
        isNeuralVoice = true

        updateNowPlayingInfo(article: article, isNeural: true)
        newPlayer.playImmediately(atRate: playbackRate)
    }

    // MARK: - Fallback Riproduzione Sintetizzatore On-Device
    private func cleanTextForSpeech(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func playSynthesizerAudio(article: Article, isIntro: Bool) {
        cleanupPlayer()
        isNeuralVoice = false

        // Costruisci il testo parlato rigorosamente pulito
        var speechText = ""
        if isIntro {
            speechText += "Benvenuto alla rassegna vocale di CyberNews. Ecco le notizie di sicurezza di oggi. "
        } else if isDailyBriefingMode {
            speechText += "Prossima notizia. "
        }

        let cleanTitle = cleanTextForSpeech(article.titleIt)
        speechText += "Fonte: \(article.sourceName). Livello di rischio: \(article.threatLevel.rawValue). "
        speechText += "\(cleanTitle). "

        if !article.summaryPoints.isEmpty {
            speechText += "Sintesi: "
            for (idx, point) in article.summaryPoints.enumerated() {
                let cleanPoint = cleanTextForSpeech(point)
                if !cleanPoint.isEmpty {
                    speechText += "Punto \(idx + 1): \(cleanPoint). "
                }
            }
        }

        if let action = article.actionMitigation, !action.isEmpty {
            let cleanAction = cleanTextForSpeech(action)
            if !cleanAction.isEmpty {
                speechText += "Azione consigliata: \(cleanAction). "
            }
        }

        let utterance = AVSpeechUtterance(string: speechText)
        if let italianVoice = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = italianVoice
        }

        let baseRate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate, max(AVSpeechUtteranceMinimumSpeechRate, baseRate * (playbackRate / 1.0)))
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.3

        isPlaying = true
        isPaused = false

        updateNowPlayingInfo(article: article, isNeural: false)
        synthesizer.speak(utterance)
    }

    public func next() {
        guard hasNext else {
            speakOutroAndStop()
            return
        }
        cleanupPlayer()
        synthesizer.stopSpeaking(at: .immediate)
        currentIndex += 1
        playCurrentQueueItem(isIntro: false)
    }

    public func previous() {
        guard hasPrevious else { return }
        cleanupPlayer()
        synthesizer.stopSpeaking(at: .immediate)
        currentIndex -= 1
        playCurrentQueueItem(isIntro: false)
    }

    public func pause() {
        if isNeuralVoice, let p = player {
            p.pause()
            isPlaying = false
            isPaused = true
            updatePlaybackState(isPlaying: false)
        } else if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPlaying = false
            isPaused = true
            updatePlaybackState(isPlaying: false)
        }
    }

    public func resume() {
        if isNeuralVoice, let p = player {
            p.playImmediately(atRate: playbackRate)
            isPlaying = true
            isPaused = false
            updatePlaybackState(isPlaying: true)
        } else if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
            isPaused = false
            updatePlaybackState(isPlaying: true)
        }
    }

    public func stop() {
        cleanupPlayer()
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
        currentArticleId = nil
        currentArticle = nil
        isDailyBriefingMode = false
        isNeuralVoice = false
        clearNowPlayingInfo()

        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func speakOutroAndStop() {
        cleanupPlayer()
        isNeuralVoice = false
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

    private func updateNowPlayingInfo(article: Article, isNeural: Bool = false) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = article.titleIt
        let voiceBadge = isNeural ? "Voce Neurale AI" : "Voce Dispositivo"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "CyberNews • \(article.sourceName) (\(voiceBadge))"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = isDailyBriefingMode ? "Rassegna del Giorno (\(playlistProgressText))" : "Cyber Briefing"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackRate) : 0.0

        if isNeural, let item = player?.currentItem {
            let duration = CMTimeGetSeconds(item.duration)
            if duration.isFinite && duration > 0 {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updatePlaybackState(isPlaying: Bool) {
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackRate) : 0.0
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
