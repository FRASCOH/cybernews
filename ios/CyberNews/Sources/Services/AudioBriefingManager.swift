import Foundation
import AVFoundation
import Combine

@MainActor
public final class AudioBriefingManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = AudioBriefingManager()

    private let synthesizer = AVSpeechSynthesizer()

    @Published public var isPlaying: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var currentArticleId: String? = nil

    override private init() {
        super.init()
        synthesizer.delegate = self
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

    public func play(article: Article) {
        // Se sta già riproducendo questo stesso articolo ed era in pausa, riprendi
        if currentArticleId == article.id && isPaused {
            resume()
            return
        }

        stop()
        configureAudioSession()

        // Costruisci il testo narrato in italiano naturale e chiaro
        var speechText = "CyberNews Briefing. Fonte: \(article.sourceName). Livello di rischio: \(article.threatLevel.rawValue). "
        speechText += "\(article.titleIt). "

        if !article.summaryPoints.isEmpty {
            speechText += "Sintesi dei punti chiave. "
            for (idx, point) in article.summaryPoints.enumerated() {
                speechText += "Punto \(idx + 1): \(point). "
            }
        }

        if let action = article.actionMitigation, !action.isEmpty {
            speechText += "Azione di mitigazione raccomandata: \(action). "
        }

        let utterance = AVSpeechUtterance(string: speechText)
        
        // Seleziona la voce italiana con fallback intelligente
        if let italianVoice = AVSpeechSynthesisVoice(language: "it-IT") {
            utterance.voice = italianVoice
        }
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.96 // Velocità naturale e cadenzata
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.2

        currentArticleId = article.id
        isPlaying = true
        isPaused = false

        synthesizer.speak(utterance)
    }

    public func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPlaying = false
            isPaused = true
        }
    }

    public func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
            isPaused = false
        }
    }

    public func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
        currentArticleId = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate (nonisolated per compatibilità Swift Concurrency)
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.isPaused = false
            self.currentArticleId = nil
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.isPaused = false
            self.currentArticleId = nil
        }
    }
}
