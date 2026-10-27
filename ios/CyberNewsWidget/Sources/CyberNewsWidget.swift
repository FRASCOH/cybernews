import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 1. Enum Argomenti / Categorie Configurabili
public enum WidgetCategoryEnum: String, AppEnum {
    case all = "ALL"
    case nis2GoldenPower = "NIS2_GOLDEN_POWER"
    case vulnerabilita = "VULNERABILITA_ZERODAY"
    case ransomware = "RANSOMWARE_ATTACCHI"
    case complianceIso = "COMPLIANCE_ISO"
    case threatIntel = "THREAT_INTEL"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Argomento"

    public static var caseDisplayRepresentations: [WidgetCategoryEnum: DisplayRepresentation] = [
        .all: "Tutte le Notizie",
        .nis2GoldenPower: "NIS2 & Golden Power",
        .vulnerabilita: "Zero-Day & Vulnerabilità",
        .ransomware: "Ransomware & Attacchi",
        .complianceIso: "ISO 27001 & DORA",
        .threatIntel: "Threat Intelligence"
    ]

    public var displayName: String {
        switch self {
        case .all:               return "In Primo Piano"
        case .nis2GoldenPower:   return "NIS2 & Golden Power"
        case .vulnerabilita:     return "Zero-Day & Bug"
        case .ransomware:        return "Ransomware"
        case .complianceIso:     return "ISO 27001 & DORA"
        case .threatIntel:       return "Threat Intel"
        }
    }
}

// MARK: - 2. Intent di Configurazione per l'Utente
public struct SelectCategoryIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Scegli Argomento"
    public static var description = IntentDescription("Seleziona l'argomento di cui vuoi monitorare l'ultima notizia importante.")

    @Parameter(title: "Argomento", default: .all)
    public var category: WidgetCategoryEnum

    public init() {}
    public init(category: WidgetCategoryEnum) {
        self.category = category
    }
}

// MARK: - 3. Timeline Provider con Supporto Configurazione Utente
struct ConfigurableProvider: AppIntentTimelineProvider {
    typealias Entry = CyberNewsEntry
    typealias Intent = SelectCategoryIntent

    private var fallbackEntry: CyberNewsEntry {
        CyberNewsEntry(
            date: Date(),
            title: "Vulnerabilità critiche RCE PHP2Shell (CVE-2026-109618/19)",
            source: "The Hacker News",
            threatLevel: "CRITICO",
            categoryName: "Zero-Day & Bug",
            action: "Aggiornare immediatamente a PHP 8.5.12 o versioni patchate.",
            summaryPoints: [
                "Falla RCE non autenticata su core PHP da 5.4 a 8.5.",
                "Sfruttamento attivo confermato in-the-wild.",
                "CISA ha ordinato la patch con inserimento nel catalogo KEV."
            ],
            criticalCount: 4
        )
    }

    func placeholder(in context: Context) -> CyberNewsEntry {
        fallbackEntry
    }

    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> CyberNewsEntry {
        await loadEntry(for: configuration.category)
    }

    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<CyberNewsEntry> {
        let entry = await loadEntry(for: configuration.category)
        // Aggiorna il widget ogni 30 minuti
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadEntry(for category: WidgetCategoryEnum) async -> CyberNewsEntry {
        // 1. Prova a leggere dalla cache condivisa dell'App (0ms di latenza)
        if let sharedDefaults = UserDefaults(suiteName: "group.it.cybernews.app"),
           let cachedData = sharedDefaults.data(forKey: "cached_articles_json"),
           let json = try? JSONSerialization.jsonObject(with: cachedData) as? [[String: Any]],
           !json.isEmpty {
            return filterAndBuildEntry(from: json, category: category)
        }

        // 2. Prova a scaricare le notizie in tempo reale da Supabase
        if let liveArticles = await fetchLiveFromSupabase(), !liveArticles.isEmpty {
            return filterAndBuildEntry(from: liveArticles, category: category)
        }

        // 3. Fallback al file locale latest_news.json
        if let url = Bundle.main.url(forResource: "latest_news", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           !json.isEmpty {
            return filterAndBuildEntry(from: json, category: category)
        }

        return fallbackEntry
    }

    private func fetchLiveFromSupabase() async -> [[String: Any]]? {
        let endpoint = "https://stkmmwwpwrbnkigkuwdp.supabase.co/rest/v1/news_articles?select=*&order=created_at.desc&limit=30"
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0a21td3dwd3JibmtpZ2t1d2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwOTgyMTksImV4cCI6MjEwODY3NDIxOX0.oT8tH06YDvfve36AIg0bvrrIa2bjXCFIJxPYLBxcoB0"

        guard let url = URL(string: endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 6

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            }
        } catch {
            print("⚠️ Widget offline fallback")
        }
        return nil
    }

    private func filterAndBuildEntry(from articles: [[String: Any]], category: WidgetCategoryEnum) -> CyberNewsEntry {
        let matching: [[String: Any]]
        if category == .all {
            matching = articles
        } else {
            let filtered = articles.filter { ($0["category"] as? String) == category.rawValue }
            matching = filtered.isEmpty ? articles : filtered
        }

        // Cerca prima un allarme critico, altrimenti il più recente
        let top = matching.first { ($0["threat_level"] as? String) == "CRITICO" } ?? matching.first ?? articles.first!
        let criticals = articles.filter { ($0["threat_level"] as? String) == "CRITICO" }

        let points = top["summary_points"] as? [String] ?? []

        return CyberNewsEntry(
            date: Date(),
            title: top["title_it"] as? String ?? "Nessuna notizia",
            source: top["source_name"] as? String ?? "CyberNews",
            threatLevel: top["threat_level"] as? String ?? "MEDIO",
            categoryName: category.displayName,
            action: top["action_mitigation"] as? String ?? "Verificare configurazione dei sistemi.",
            summaryPoints: points,
            criticalCount: criticals.count
        )
    }
}

// MARK: - 4. Entry Dati
struct CyberNewsEntry: TimelineEntry {
    let date: Date
    let title: String
    let source: String
    let threatLevel: String
    let categoryName: String
    let action: String
    let summaryPoints: [String]
    let criticalCount: Int

    var extendedSummary: String {
        if summaryPoints.isEmpty {
            return "Monitoraggio continuo delle fonti ufficiali per la sicurezza perimetrale e la conformità normativa."
        }
        return summaryPoints.joined(separator: " ")
    }
}

// MARK: - 5. Viste del Widget
struct CyberNewsWidgetEntryView : View {
    var entry: ConfigurableProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .systemLarge:
            largeWidgetView
        case .accessoryRectangular:
            lockScreenRectangularView
        case .accessoryInline:
            lockScreenInlineView
        default:
            mediumWidgetView
        }
    }

    // SMALL WIDGET (Home Screen)
    var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Categoria scelta
            HStack {
                Text(entry.categoryName.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                    .lineLimit(1)

                Spacer()

                if entry.threatLevel == "CRITICO" {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }

            Text(entry.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)

            Spacer()

            HStack {
                Text(entry.threatLevel)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.threatLevel == "CRITICO" ? Color.red : Color(red: 1.0, green: 0.42, blue: 0.0))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.08)))

                Spacer()

                Text(entry.source)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(14)
        .containerBackground(Color(red: 0.04, green: 0.04, blue: 0.05), for: .widget)
    }

    // MEDIUM WIDGET (Home Screen)
    var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 6, height: 6)

                    Text(entry.categoryName)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(entry.threatLevel)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(entry.threatLevel == "CRITICO" ? Color.red : Color(red: 1.0, green: 0.42, blue: 0.0))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((entry.threatLevel == "CRITICO" ? Color.red : Color(red: 1.0, green: 0.42, blue: 0.0)).opacity(0.15))
                        )

                    Text("• \(entry.source)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            // Titolo Notizia (1 riga compatta)
            Text(entry.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            // Riassunto Esteso: almeno 3 righe piene di testo
            Text(entry.extendedSummary)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(2)
                .lineLimit(3)

            Spacer(minLength: 0)

            // Box Azione Rapida
            HStack(spacing: 5) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                Text(entry.action)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.12))
            )
        }
        .padding(12)
        .containerBackground(Color(red: 0.04, green: 0.04, blue: 0.05), for: .widget)
    }

    // LARGE WIDGET (Home Screen)
    var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 8, height: 8)

                    Text("CyberNews • \(entry.categoryName)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }

                Spacer()

                Text(entry.threatLevel)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(entry.threatLevel == "CRITICO" ? Color.red : Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }

            Text(entry.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Punti sintetici AI
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.summaryPoints.prefix(2).enumerated()), id: \.offset) { _, p in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                        Text(p)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )

            Spacer()

            // Box Azione
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                    Text("AZIONE RACCOMANDATA")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }
                Text(entry.action)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.12))
            )
        }
        .padding(16)
        .containerBackground(Color(red: 0.04, green: 0.04, blue: 0.05), for: .widget)
    }

    // LOCK SCREEN (Rectangular)
    var lockScreenRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 9))
                Text("\(entry.categoryName): \(entry.threatLevel)")
                    .font(.system(size: 10, weight: .bold))
            }
            Text(entry.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
        }
    }

    // LOCK SCREEN (Inline)
    var lockScreenInlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "shield.fill")
            Text("\(entry.categoryName): \(entry.title)")
        }
    }
}

// MARK: - 6. Configurazione Widget con AppIntent
@main
struct CyberNewsWidget: Widget {
    let kind: String = "CyberNewsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCategoryIntent.self,
            provider: ConfigurableProvider()
        ) { entry in
            CyberNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CyberNews Argomenti")
        .description("Tieni premuto il widget per scegliere l'argomento (es. NIS2, Zero-Day, Ransomware) da monitorare.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}
