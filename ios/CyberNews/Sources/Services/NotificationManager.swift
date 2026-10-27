import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()
    private init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permesso notifiche concesso dall'utente")
            } else if let error = error {
                print("❌ Errore richiesta permessi notifiche: \(error)")
            }
        }
    }

    public func notifyCriticalAlert(article: Article) {
        guard article.threatLevel == .critico else { return }

        let content = UNMutableNotificationContent()
        content.title = "🚨 ALLARME CYBER CRITICO"
        content.subtitle = article.titleIt
        content.body = article.actionMitigation ?? "Consultare l'app per la procedura di mitigazione."
        content.sound = .defaultCritical
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "critico-\(article.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Errore invio notifica locale: \(error)")
            }
        }
    }
}
