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
            articleId: "art-1",
            title: "Vulnerabilità critiche RCE PHP2Shell (CVE-2026-109618/19)",
            source: "The Hacker News",
            threatLevel: "CRITICO",
            categoryName: "Zero-Day & Bug",
            action: "Aggiornare immediatamente a PHP 8.5.12 o versioni patchate.",
            summaryPoints: [
                "Falla RCE non autenticata su core PHP da 5.4 a 8.5.",
                "Sfruttamento attivo confermato in-the-wild da botnet note.",
                "CISA ha ordinato la patch con inserimento nel catalogo KEV."
            ],
            criticalCount: 4,
            targetAudience: "CISO / SecOps",
            tags: ["PHP", "RCE", "KEV", "CVE-2026"],
            publishedAt: "Oggi"
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
        let articleId = top["id"] as? String ?? top["url_hash"] as? String
        let targetAudience = top["target_audience"] as? String
        let publishedAt = top["published_at"] as? String
        let tags: [String] = {
            if let arr = top["tags"] as? [String] {
                return arr
            }
            if let str = top["tags"] as? String {
                return str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            return []
        }()

        return CyberNewsEntry(
            date: Date(),
            articleId: articleId,
            title: top["title_it"] as? String ?? "Nessuna notizia",
            source: top["source_name"] as? String ?? "CyberNews",
            threatLevel: top["threat_level"] as? String ?? "MEDIO",
            categoryName: category.displayName,
            action: top["action_mitigation"] as? String ?? "Verificare configurazione dei sistemi.",
            summaryPoints: points,
            criticalCount: criticals.count,
            targetAudience: targetAudience,
            tags: tags,
            publishedAt: publishedAt
        )
    }
}

// MARK: - 4. Entry Dati
struct CyberNewsEntry: TimelineEntry {
    let date: Date
    let articleId: String?
    let title: String
    let source: String
    let threatLevel: String
    let categoryName: String
    let action: String
    let summaryPoints: [String]
    let criticalCount: Int
    let targetAudience: String?
    let tags: [String]
    let publishedAt: String?

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
        Group {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            case .systemLarge:
                largeWidgetView
            case .systemExtraLarge:
                largeWidgetView
            case .accessoryRectangular:
                lockScreenRectangularView
            case .accessoryInline:
                lockScreenInlineView
            default:
                mediumWidgetView
            }
        }
        .widgetURL(deepLinkURL)
    }

    private var deepLinkURL: URL? {
        if let id = entry.articleId, !id.isEmpty {
            return URL(string: "cybernews://article/\(id)")
        }
        return URL(string: "cybernews://feed")
    }

    private func threatColor(for level: String) -> Color {
        switch level.uppercased() {
        case "CRITICO":
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        case "ALTO":
            return Color(red: 1.0, green: 0.58, blue: 0.0)
        case "MEDIO":
            return Color(red: 1.0, green: 0.80, blue: 0.0)
        default:
            return Color(red: 0.0, green: 0.75, blue: 1.0)
        }
    }

    // SMALL WIDGET (Home Screen)
    var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header: Categoria + Threat Level Badge
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 5.5, height: 5.5)

                    Text(entry.categoryName)
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                Text(entry.threatLevel)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(threatColor(for: entry.threatLevel))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(threatColor(for: entry.threatLevel).opacity(0.16))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(threatColor(for: entry.threatLevel).opacity(0.35), lineWidth: 0.7)
                    )
            }

            // Titolo Notizia (2 righe)
            Text(entry.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .lineSpacing(1.2)
                .fixedSize(horizontal: false, vertical: true)

            // Box Azione / Mitigazione Rapida
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 7.5))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                    Text("AZIONE")
                        .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }

                Text(entry.action)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .lineSpacing(1.1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.22), lineWidth: 0.8)
                    )
            )

            Spacer(minLength: 0)

            // Footer: Fonte + Tag primario
            HStack(alignment: .center) {
                Text(entry.source)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer(minLength: 2)

                if let firstTag = entry.tags.first, !firstTag.isEmpty {
                    Text("#\(firstTag)")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 0.40, green: 0.94, blue: 1.0))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.0, green: 0.75, blue: 1.0).opacity(0.12))
                        )
                        .lineLimit(1)
                } else if let pub = entry.publishedAt, !pub.isEmpty {
                    Text(pub)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
        }
        .padding(11)
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
                        .foregroundStyle(threatColor(for: entry.threatLevel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(threatColor(for: entry.threatLevel).opacity(0.15))
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
        VStack(alignment: .leading, spacing: 8) {
            // Header: Categoria + Fonte + Threat Level Badge
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 7, height: 7)

                    Text("CyberNews • \(entry.categoryName)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                    Text("• \(entry.source)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text(entry.threatLevel)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(threatColor(for: entry.threatLevel))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(threatColor(for: entry.threatLevel).opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(threatColor(for: entry.threatLevel).opacity(0.35), lineWidth: 0.8)
                    )
            }

            // Titolo Notizia
            Text(entry.title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Analisi Punti Chiave AI (Tutti e 3 i punti completi)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8.5))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                    Text("PUNTI CHIAVE DELL'ANALISI")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                let pointsToShow = entry.summaryPoints.isEmpty
                    ? [entry.extendedSummary]
                    : Array(entry.summaryPoints.prefix(3))

                ForEach(Array(pointsToShow.enumerated()), id: \.offset) { _, p in
                    HStack(alignment: .top, spacing: 5) {
                        Text("•")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                            .padding(.top, 1)

                        Text(p)
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )

            // Box Azione Raccomandata (con Target Audience se presente)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                    Text("AZIONE RACCOMANDATA")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                    if let target = entry.targetAudience, !target.isEmpty {
                        Spacer(minLength: 4)
                        Text("Target: \(target)")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }

                Text(entry.action)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.25), lineWidth: 1)
                    )
            )

            Spacer(minLength: 0)

            // Footer con Tag e Timestamp
            if !entry.tags.isEmpty || entry.publishedAt != nil {
                HStack(spacing: 5) {
                    ForEach(Array(entry.tags.prefix(3)), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(red: 0.40, green: 0.94, blue: 1.0))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.0, green: 0.75, blue: 1.0).opacity(0.12))
                            )
                    }

                    Spacer(minLength: 0)

                    if let pub = entry.publishedAt, !pub.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 7.5))
                            Text(pub)
                                .font(.system(size: 8.5, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .padding(13)
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryInline])
    }
}
