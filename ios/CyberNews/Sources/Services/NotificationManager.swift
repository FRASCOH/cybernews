import Foundation
import UserNotifications
import UIKit

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    private let notifiedIdsKey = "cybernews_notified_article_ids"

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permesso notifiche concesso dall'utente")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Errore richiesta permessi notifiche: \(error)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    public func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    /// Controlla se sono arrivate nuove notizie e invia notifiche push locali
    public func checkAndNotifyNewArticles(articles: [Article]) {
        let isEnabled = UserDefaults.standard.object(forKey: "push_notifications_enabled") as? Bool ?? true
        guard isEnabled, !articles.isEmpty else { return }

        let notifyAll = UserDefaults.standard.object(forKey: "notify_all_news") as? Bool ?? true
        let notifyCritical = UserDefaults.standard.object(forKey: "notify_critical") as? Bool ?? true
        let notifyGovernance = UserDefaults.standard.object(forKey: "notify_governance") as? Bool ?? true

        var notifiedIds = Set(UserDefaults.standard.stringArray(forKey: notifiedIdsKey) ?? [])

        // Se è la prima volta, memorizza gli ID attuali per evitare spam iniziale
        if notifiedIds.isEmpty {
            for art in articles {
                notifiedIds.insert(art.id)
            }
            UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedIdsKey)
            return
        }

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

    /// Invia una notifica di prova verificando prima lo stato dei permessi
    public func sendTestNotification(completion: @escaping (Bool, String, Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.dispatchTestNotification()
                DispatchQueue.main.async {
                    completion(true, "Notifica di test inviata! Apparirà dall'alto tra 1 secondo (anche con l'app aperta).", false)
                }

            case .notDetermined:
                self.requestAuthorization { granted in
                    if granted {
                        self.dispatchTestNotification()
                        completion(true, "Permesso concesso! Notifica di test inviata.", false)
                    } else {
                        completion(false, "Permesso notifiche rifiutato. Puoi abilitarlo dalle Impostazioni di iOS.", true)
                    }
                }

            case .denied:
                DispatchQueue.main.async {
                    completion(false, "Le notifiche sono DISATTIVATE per CyberNews nelle Impostazioni di iOS. Tocca il tasto qui sotto per aprirle e abilitarle.", true)
                }

            @unknown default:
                self.dispatchTestNotification()
                DispatchQueue.main.async {
                    completion(true, "Notifica di test programmata.", false)
                }
            }
        }
    }

    private func dispatchTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚨 [TEST CRITICO] CyberNews Alert"
        content.subtitle = "Vulnerabilità RCE Rilevata (Simulazione)"
        content.body = "Azione consigliata: Rilasciata patch di emergenza. Verifica e aggiorna i server esposti."
        content.sound = .defaultCritical
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Errore add request: \(error)")
            }
        }
    }
}
