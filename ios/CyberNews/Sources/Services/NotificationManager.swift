import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()
    private init() {}

    private let lastSeenKey = "cybernews_last_seen_article_id"
    private let notifiedIdsKey = "cybernews_notified_article_ids"

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permesso notifiche concesso dall'utente")
            } else if let error = error {
                print("❌ Errore richiesta permessi notifiche: \(error)")
            }
        }
    }

    /// Controlla se sono arrivate nuove notizie e invia notifiche in base alle preferenze dell'utente
    public func checkAndNotifyNewArticles(articles: [Article]) {
        let isEnabled = UserDefaults.standard.object(forKey: "push_notifications_enabled") as? Bool ?? true
        guard isEnabled, !articles.isEmpty else { return }

        let notifyAll = UserDefaults.standard.object(forKey: "notify_all_news") as? Bool ?? true
        let notifyCritical = UserDefaults.standard.object(forKey: "notify_critical") as? Bool ?? true
        let notifyGovernance = UserDefaults.standard.object(forKey: "notify_governance") as? Bool ?? true

        var notifiedIds = Set(UserDefaults.standard.stringArray(forKey: notifiedIdsKey) ?? [])

        // Se è la prima volta che l'app viene avviata, memorizza gli ID attuali per non spammare l'utente con 20 notifiche
        if notifiedIds.isEmpty {
            for art in articles {
                notifiedIds.insert(art.id)
            }
            UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedIdsKey)
            return
        }

        // Trova gli articoli nuovi non ancora notificati
        let newArticles = articles.filter { !notifiedIds.contains($0.id) }

        for article in newArticles {
            var shouldNotify = false

            if notifyAll {
                shouldNotify = true
            } else if notifyCritical && article.threatLevel == .critico {
                shouldNotify = true
            } else if notifyGovernance && (article.category == .nis2GoldenPower || article.category == .complianceIso) {
                shouldNotify = true
            }

            if shouldNotify {
                postNotification(for: article)
            }

            notifiedIds.insert(article.id)
        }

        UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedIdsKey)
    }

    public func postNotification(for article: Article) {
        let content = UNMutableNotificationContent()
        
        let iconPrefix = article.threatLevel == .critico ? "🚨 [CRITICO]" : "🛡️ [CyberNews]"
        content.title = "\(iconPrefix) \(article.sourceName)"
        content.subtitle = article.titleIt
        content.body = article.actionMitigation ?? (article.summaryPoints.first ?? "Nuovo aggiornamento di sicurezza.")
        
        if article.threatLevel == .critico {
            content.sound = .defaultCritical
        } else {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "news-\(article.id)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Errore invio notifica: \(error)")
            }
        }
    }

    /// Invia una notifica di prova immediata per verificare audio, badge e anteprima
    public func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚨 [TEST] CyberNews Alert"
        content.subtitle = "Vulnerabilità RCE rilevata (Esempio Test)"
        content.body = "Azione consigliata: Patch d'emergenza rilasciata. Verifica la configurazione dei sistemi."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
