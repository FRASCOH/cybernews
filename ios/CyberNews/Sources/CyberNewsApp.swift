import SwiftUI
import SwiftData

@main
struct CyberNewsApp: App {
    init() {
        // Richiedi permessi per gli allarmi critici all'avvio
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: SavedArticle.self)
    }
}
