import SwiftUI
import SwiftData

@main
struct CyberNewsApp: App {
    @AppStorage("supabase_url") private var supabaseURL: String = ""
    @AppStorage("supabase_anon_key") private var supabaseAnonKey: String = ""

    init() {
        // Inizializza i parametri del service se già memorizzati
        let url = UserDefaults.standard.string(forKey: "supabase_url") ?? ""
        let key = UserDefaults.standard.string(forKey: "supabase_anon_key") ?? ""
        NewsAPIService.shared.supabaseURL = url
        NewsAPIService.shared.supabaseAnonKey = key
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: SavedArticle.self)
    }
}
