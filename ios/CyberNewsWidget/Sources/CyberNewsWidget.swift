import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CyberNewsEntry {
        fallbackEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (CyberNewsEntry) -> ()) {
        let entry = loadLatestEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadLatestEntry()
        // Aggiorna ogni 30 minuti
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private var fallbackEntry: CyberNewsEntry {
        CyberNewsEntry(
            date: Date(),
            title: "Vulnerabilità critiche RCE PHP2Shell (CVE-2026-109618/19)",
            source: "The Hacker News",
            threatLevel: "CRITICO",
            action: "Aggiornare immediatamente a PHP 8.5.12 o versioni patchate.",
            criticalCount: 4
        )
    }

    private func loadLatestEntry() -> CyberNewsEntry {
        guard let url = Bundle.main.url(forResource: "latest_news", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !json.isEmpty else {
            return fallbackEntry
        }

        let criticals = json.filter { ($0["threat_level"] as? String) == "CRITICO" }
        let top = criticals.first ?? json.first!

        return CyberNewsEntry(
            date: Date(),
            title: top["title_it"] as? String ?? "Nessun allarme critico",
            source: top["source_name"] as? String ?? "CyberNews",
            threatLevel: top["threat_level"] as? String ?? "MEDIO",
            action: top["action_mitigation"] as? String ?? "Consultare bollettino.",
            criticalCount: criticals.count
        )
    }
}

// MARK: - Entry
struct CyberNewsEntry: TimelineEntry {
    let date: Date
    let title: String
    let source: String
    let threatLevel: String
    let action: String
    let criticalCount: Int
}

// MARK: - Widget View
struct CyberNewsWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 7, height: 7)

                    Text("CyberNews")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }

                Spacer()

                Text("\(entry.criticalCount)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }

            Text(entry.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)

            Spacer()

            HStack {
                Text(entry.threatLevel)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.15)))

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
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.42, blue: 0.0))
                        .frame(width: 8, height: 8)

                    Text("Cyber")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("News")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(entry.threatLevel)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.15))
                                .overlay(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))
                        )

                    Text("• \(entry.source)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Titolo Allarme
            Text(entry.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            // Box Azione Rapida
            HStack(spacing: 6) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.0))

                Text(entry.action)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.12))
            )
        }
        .padding(14)
        .containerBackground(Color(red: 0.04, green: 0.04, blue: 0.05), for: .widget)
    }

    // LOCK SCREEN (Rectangular)
    var lockScreenRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 10))

                Text("ALLARME \(entry.threatLevel)")
                    .font(.system(size: 10, weight: .bold))
            }

            Text(entry.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)

            Text(entry.action)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // LOCK SCREEN (Inline)
    var lockScreenInlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "shield.checkered")
            Text("🚨 \(entry.title)")
        }
    }
}

// MARK: - Widget Configuration
@main
struct CyberNewsWidget: Widget {
    let kind: String = "CyberNewsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CyberNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CyberNews Alerts")
        .description("Monitora in tempo reale gli allarmi critici di sicurezza e le azioni di mitigazione.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
