import Foundation

public final class NewsAPIService {
    public static let shared = NewsAPIService()
    private init() {}

    // Inserire le credenziali Supabase (opzionale, se vuote usa i dati simulati realistici)
    public var supabaseURL: String = ""
    public var supabaseAnonKey: String = ""

    public func fetchArticles() async throws -> [Article] {
        // Se Supabase è configurato, effettua la chiamata REST
        if !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty,
           let url = URL(string: "\(supabaseURL)/rest/v1/news_articles?select=*&order=created_at.desc&limit=50") {
            
            var request = URLRequest(url: url)
            request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    return try decoder.decode([Article].self, from: data)
                }
            } catch {
                print("⚠️ Fallback ai dati seed locali: \(error)")
            }
        }

        // 1. Prova a caricare il feed JSON statico generato dall'ingestion (se presente nel bundle)
        if let bundleUrl = Bundle.main.url(forResource: "latest_news", withExtension: "json"),
           let data = try? Data(contentsOf: bundleUrl),
           let localArticles = try? JSONDecoder().decode([Article].self, from: data),
           !localArticles.isEmpty {
            return localArticles
        }

        // 2. Dati Seed Realistici ed Esemplari come fallback finale
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
            ),
            Article(
                id: "art-4",
                urlHash: "hash4",
                titleIt: "Nuova campagna Ransomware 'Akira' colpisce PMI e sanità in Europa",
                originalTitle: "Akira ransomware surge targeting European healthcare and industrial sectors",
                summaryPoints: [
                    "Gli attaccanti sfruttano credenziali VPN compromesse e mancanza di autenticazione a due fattori (MFA).",
                    "Esfiltrazione massiva di dati prima della cifratura per praticare la doppia estorsione.",
                    "Impiego di tool legittimi per disabilitare software EDR/antivirus locali."
                ],
                actionMitigation: "Forzare MFA su tutti gli accessi VPN/RDP e verificare la segregazione dei backup offline immutabili.",
                threatLevel: .alto,
                category: .ransomware,
                targetAudience: "SysAdmin",
                tags: ["Ransomware", "Akira", "VPN", "MFA", "BleepingComputer"],
                sourceName: "BleepingComputer",
                sourceUrl: "https://www.bleepingcomputer.com",
                publishedAt: "5 ore fa",
                isBreaking: false
            ),
            Article(
                id: "art-5",
                urlHash: "hash5",
                titleIt: "Transizione ISO/IEC 27001:2022: Guida ai nuovi controlli di Threat Intel e Cloud",
                originalTitle: "ISO 27001:2022 migration: implementation roadmap for Annex A controls",
                summaryPoints: [
                    "Focalizzazione sui controlli dell'Annex A relativi a Threat Intelligence (controllo 5.7) e sicurezza cloud (controllo 5.23).",
                    "I certificati basati sulla vecchia versione 2013 scadranno definitivamente nei prossimi mesi.",
                    "Integrazione richiesta tra SGSI e processi di business continuity previsti da DORA."
                ],
                actionMitigation: "Completare il gap assessment interno e aggiornare la dichiarazione di applicabilità (SoA) per includere i nuovi 11 controlli.",
                threatLevel: .informativo,
                category: .complianceIso,
                targetAudience: "CISO & Auditor",
                tags: ["ISO 27001", "SGSI", "Audit", "DORA"],
                sourceName: "Cybersecurity360",
                sourceUrl: "https://www.cybersecurity360.it",
                publishedAt: "1 giorno fa",
                isBreaking: false
            ),
            Article(
                id: "art-6",
                urlHash: "hash6",
                titleIt: "CISA KEV: Aggiunte 3 vulnerabilità Microsoft e Linux sfruttate attivamente",
                originalTitle: "CISA adds three known exploited vulnerabilities to catalog",
                summaryPoints: [
                    "Inserite nel catalogo KEV vulnerabilità che permettono privilege escalation locale e bypass di autenticazione.",
                    "Fissate le scadenze vincolanti per le agenzie federali e fortemente raccomandate per i privati.",
                    "Codici CVE: CVE-2024-38124, CVE-2024-43093."
                ],
                actionMitigation: "Verificare l'inventario degli endpoint e procedere alla distribuzione immediata degli aggiornamenti cumulativi.",
                threatLevel: .medio,
                category: .vulnerabilita,
                targetAudience: "SysAdmin",
                tags: ["CISA", "KEV", "Windows", "Patch"],
                sourceName: "CISA Alerts",
                sourceUrl: "https://www.cisa.gov",
                publishedAt: "1 giorno fa",
                isBreaking: false
            )
        ]
    }
}
