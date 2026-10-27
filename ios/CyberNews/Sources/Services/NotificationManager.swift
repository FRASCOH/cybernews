import Foundation
import UserNotifications
import UIKit
import Combine

public final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    private let lastSeenKey = "cybernews_last_seen_article_id"
    private let notifiedIdsKey = "cybernews_notified_article_ids"
    private let historyKey = "cybernews_notifications_history"

    @Published public var notifications: [DeliveredNotification] = []
    @Published public var unreadCount: Int = 0

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadHistory()
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let list = try? JSONDecoder().decode([DeliveredNotification].self, from: data) {
            self.notifications = list
            self.unreadCount = list.filter { !$0.isRead }.count
        } else {
            // Se la cronologia è vuota, inseriamo un paio di notifiche di esempio realistiche
            let sampleList: [DeliveredNotification] = [
                DeliveredNotification(
                    id: "sample-1",
                    title: "🚨 [CRITICO] The Hacker News",
                    subtitle: "Vulnerabilità RCE PHP2Shell (CVE-2026-109618/19)",
                    body: "Azione: Aggiornare subito a PHP 8.5.12 o bloccare i path esposti.",
                    threatLevel: .critico,
                    timestamp: Date().addingTimeInterval(-1800),
                    isRead: false
                ),
                DeliveredNotification(
                    id: "sample-2",
                    title: "🛡️ [NIS2] Cybersecurity360",
                    subtitle: "Linee guida ACN per soggetti essenziali NIS2",
                    body: "Azione: Avviare la verifica perimetrale e notifica entro 24h.",
                    threatLevel: .alto,
                    timestamp: Date().addingTimeInterval(-7200),
                    isRead: true
                )
            ]
            self.notifications = sampleList
            self.unreadCount = sampleList.filter { !$0.isRead }.count
            saveHistory()
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
        DispatchQueue.main.async {
            self.unreadCount = self.notifications.filter { !$0.isRead }.count
        }
    }

    public func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
        saveHistory()
    }

    public func markAsRead(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isRead = true
            saveHistory()
        }
    }

    public func clearHistory() {
        notifications.removeAll()
        saveHistory()
    }

    public func deleteNotification(id: String) {
        notifications.removeAll(where: { $0.id == id })
        saveHistory()
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permesso notifiche concesso dall'utente")
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

        // Aggiungi alla cronologia notifiche dell'app
        let historyItem = DeliveredNotification(
            articleId: article.id,
            title: content.title,
            subtitle: content.subtitle,
            body: content.body,
            threatLevel: article.threatLevel,
            timestamp: Date(),
            isRead: false
        )
        DispatchQueue.main.async {
            self.notifications.insert(historyItem, at: 0)
            self.saveHistory()
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

        // Salva nello storico
        let item = DeliveredNotification(
            title: content.title,
            subtitle: content.subtitle,
            body: content.body,
            threatLevel: .critico,
            timestamp: Date(),
            isRead: false
        )
        DispatchQueue.main.async {
            self.notifications.insert(item, at: 0)
            self.saveHistory()
        }
    }
}
