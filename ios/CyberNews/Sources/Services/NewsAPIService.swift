import Foundation
import WidgetKit

public final class NewsAPIService {
    public static let shared = NewsAPIService()
    private init() {
        // Carica la cache disco in memoria all'avvio
        if let initial = loadFromDisk() {
            self.memoryCache = initial
        }
    }

    // Credenziali Supabase predefinite (chiave anon pubblica protetta da RLS in sola lettura)
    public let supabaseURL: String = "https://stkmmwwpwrbnkigkuwdp.supabase.co"
    public let supabaseAnonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0a21td3dwd3JibmtpZ2t1d2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwOTgyMTksImV4cCI6MjEwODY3NDIxOX0.oT8tH06YDvfve36AIg0bvrrIa2bjXCFIJxPYLBxcoB0"

    private var memoryCache: [Article] = []
    private var lastFetchTime: Date? = nil
    private let cacheTTL: TimeInterval = 180 // 3 minuti di TTL per evitare refresh ridondanti

    // MARK: - Cache Helpers
    private var localCacheURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("cybernews_cache.json")
    }

    private var sharedAppGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.it.cybernews.app")
    }

    /// Ritorna istantaneamente le notizie in cache (latenza 0ms all'avvio)
    public func getCachedArticles() -> [Article]? {
        if !memoryCache.isEmpty {
            return memoryCache
        }
        return loadFromDisk()
    }

    private func loadFromDisk() -> [Article]? {
        guard let url = localCacheURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Article].self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToDiskAndShared(articles: [Article]) {
        self.memoryCache = articles
        self.lastFetchTime = Date()

        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(articles)

                // 1. Salva nella cache sandbox locale
                if let localUrl = self.localCacheURL {
                    try data.write(to: localUrl, options: .atomic)
                }

                // 2. Condividi con il Widget (App Group se configurato)
                self.sharedAppGroupDefaults?.set(data, forKey: "cached_articles_json")

                // 3. Notifica a WidgetKit di aggiornare i widget della schermata Home
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("⚠️ Errore salvataggio cache notizie: \(error)")
            }
        }
    }

    // MARK: - Fetching
    public func fetchArticles(forceRefresh: Bool = false) async throws -> [Article] {
        // Se abbiamo una cache fresca e non è un force-refresh manuale (es. pull-to-refresh), usa la cache
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTTL,
           !memoryCache.isEmpty {
            return memoryCache
        }

        // Chiamata REST a Supabase
        if !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty,
           let url = URL(string: "\(supabaseURL)/rest/v1/news_articles?select=*&order=created_at.desc&limit=50") {

            var request = URLRequest(url: url)
            request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 8

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let fetchedArticles = try decoder.decode([Article].self, from: data)
                    if !fetchedArticles.isEmpty {
                        saveToDiskAndShared(articles: fetchedArticles)
                        return fetchedArticles
                    }
                }
            } catch {
                print("⚠️ Connessione Supabase fallita, carico cache locale: \(error)")
            }
        }

        // Fallback 1: Cache disco precedentemente salvata
        if let diskArticles = loadFromDisk(), !diskArticles.isEmpty {
            self.memoryCache = diskArticles
            return diskArticles
        }

        // Fallback 2: Feed JSON bundle pre-incluso
        if let bundleUrl = Bundle.main.url(forResource: "latest_news", withExtension: "json"),
           let data = try? Data(contentsOf: bundleUrl),
           let localArticles = try? JSONDecoder().decode([Article].self, from: data),
           !localArticles.isEmpty {
            return localArticles
        }

        // Fallback 3: Dati seed di emergenza
        return getMockArticles()
    }

    public func getMockArticles() -> [Article] {
        return [
            Article(
                id: "art-1",
                urlHash: "hash1",
                titleIt: "ACN: Allerta critica su vulnerabilità zero-day in appliance perimetrali",
                originalTitle: "Critical zero-day vulnerability actively exploited in perimeter devices",
                summaryPoints: [
                    "Sfruttamento attivo in corso mirato a infrastrutture critiche ed enti governativi italiani.",
                    "Vulnerabilità consente l'esecuzione remota di codice non autenticata (RCE) via porta 443.",
                    "CSIRT Italia ha diramato un bollettino con indicatori di compromissione (IoC) prioritari."
                ],
                actionMitigation: "Applicare immediatamente la patch di emergenza del vendor. Se non possibile, disabilitare l'interfaccia di gestione esposta su WAN.",
                threatLevel: .critico,
                category: .vulnerabilita,
                targetAudience: "SysAdmin & CISO",
                tags: ["ACN", "CSIRT", "Zero-Day", "RCE", "Firewall"],
                sourceName: "ACN",
                sourceUrl: "https://www.acn.gov.it",
                publishedAt: "25 min fa",
                isBreaking: true
            ),
            Article(
                id: "art-2",
                urlHash: "hash2",
                titleIt: "NIS2 Italia: Pubblicate le linee guida ACN per i soggetti essenziali",
                originalTitle: "Italy NIS2 transposition: essential and important entities registration guidelines",
                summaryPoints: [
                    "L'ACN ha pubblicato le istruzioni operative per l'iscrizione alla piattaforma NIS2 (D.Lgs. 138/2024).",
                    "Definiti i criteri dimensionali e di fatturato per i settori energia, sanità, cloud e PA.",
                    "Obbligo perentorio di notifica iniziale degli incidenti significativi entro 24 ore dall'evento."
                ],
                actionMitigation: "Avviare la verifica formale del perimetro aziendale e nominare il referente unico di contatto per le comunicazioni con ACN.",
                threatLevel: .alto,
                category: .nis2GoldenPower,
                targetAudience: "CISO & DPO",
                tags: ["NIS2", "D.Lgs. 138/2024", "ACN", "Compliance"],
                sourceName: "Cybersecurity360",
                sourceUrl: "https://www.cybersecurity360.it",
                publishedAt: "2 ore fa",
                isBreaking: false
            ),
            Article(
                id: "art-3",
                urlHash: "hash3",
                titleIt: "Golden Power: Nuove prescrizioni su forniture 5G e datacenter strategici",
                originalTitle: "Government exercises special powers on 5G critical infrastructure supply chain",
                summaryPoints: [
                    "Il Consiglio dei Ministri ha deliberato l'esercizio dei poteri speciali con prescrizioni mirate.",
                    "Richiesti test di sicurezza e certificazioni CVCN per apparati core di fornitori extra-UE.",
                    "Obbligo di monitoraggio continuo degli accessi privilegiati da remoto da parte dei vendor."
                ],
                actionMitigation: "Mappare l'intera catena di fornitura hardware/software per i nodi critici e preparare la documentazione di conformità Golden Power.",
                threatLevel: .alto,
                category: .nis2GoldenPower,
                targetAudience: "CISO & Legal",
                tags: ["Golden Power", "5G", "Presidenza CdM", "CVCN"],
                sourceName: "Agenda Digitale",
                sourceUrl: "https://www.agendadigitale.eu",
                publishedAt: "4 ore fa",
                isBreaking: false
            )
        ]
    }

    // MARK: - Device Token Registration
    public func registerDeviceToken(_ token: String) async {
        guard !token.isEmpty, let url = URL(string: "\(supabaseURL)/rest/v1/device_tokens") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let payload: [String: Any] = [
            "device_token": token,
            "platform": "ios"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) {
                print("📲 Token APNs registrato con successo nel database cloud.")
            }
        } catch {
            print("ℹ️ Sincronizzazione token APNs: \(error.localizedDescription)")
        }
    }
}
