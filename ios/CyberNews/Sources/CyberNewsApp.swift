import SwiftUI
import SwiftData
import BackgroundTasks
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📲 APNs Device Token ricevuto:", token)
        UserDefaults.standard.set(token, forKey: "apns_device_token")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("ℹ️ Registrazione APNs remota:", error.localizedDescription)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            if let fresh = try? await NewsAPIService.shared.fetchArticles(forceRefresh: true) {
                NotificationManager.shared.checkAndNotifyNewArticles(articles: fresh)
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}

@main
struct CyberNewsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.requestAuthorization()
        registerBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: SavedArticle.self)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleBackgroundRefresh()
            }
        }
    }

    private func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "it.cybernews.app.refresh",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleBackgroundRefresh(task: refreshTask)
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        let workTask = Task {
            if let fresh = try? await NewsAPIService.shared.fetchArticles(forceRefresh: true) {
                NotificationManager.shared.checkAndNotifyNewArticles(articles: fresh)
            }
        }

        task.expirationHandler = {
            workTask.cancel()
        }

        Task {
            _ = await workTask.result
            task.setTaskCompleted(success: true)
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "it.cybernews.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Prova ogni 15 minuti in background
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("ℹ️ Programmazione background task: \(error.localizedDescription)")
        }
    }
}
