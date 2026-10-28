import SwiftUI

public struct GovernanceView: View {
    @ObservedObject public var viewModel: NewsFeedViewModel
    @State private var selectedDirective: DirectiveType = .nis2
    @State private var selectedArticle: Article? = nil

    // Stato Checklist Interattiva
    @AppStorage("check_acn_registered") private var checkAcnRegistered: Bool = false
    @AppStorage("check_incident_24h") private var checkIncident24h: Bool = false
    @AppStorage("check_supply_chain") private var checkSupplyChain: Bool = false
    @AppStorage("check_mfa_backup") private var checkMfaBackup: Bool = false

    public init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
    }

    public enum DirectiveType: String, CaseIterable, Identifiable {
        case nis2 = "NIS2"
        case goldenPower = "Golden Power"
        case dora = "DORA"
        case iso27001 = "ISO 27001"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .nis2:        return "building.columns.fill"
            case .goldenPower: return "shield.checkered"
            case .dora:        return "eurosign.circle.fill"
            case .iso27001:    return "checkmark.seal.fill"
            }
        }

        public var lawReference: String {
            switch self {
            case .nis2:        return "D.Lgs. 138/2024 • Direttiva UE 2022/2555"
            case .goldenPower: return "D.L. 21/2012 • Perimetro Sicurezza Nazionale"
            case .dora:        return "Regolamento UE 2022/2554 (DORA)"
            case .iso27001:    return "Standard Internazionale ISO/IEC 27001:2022"
            }
        }
    }

    private var readinessScore: Int {
        var score = 0
        if checkAcnRegistered { score += 25 }
        if checkIncident24h { score += 25 }
        if checkSupplyChain { score += 25 }
        if checkMfaBackup { score += 25 }
        return score
    }

    // Articoli strettamente normativi legati alla direttiva selezionata
    private var relevantArticles: [Article] {
        viewModel.articles.filter { article in
            article.category == .nis2GoldenPower || article.category == .complianceIso ||
            article.tags.contains(where: { $0.localizedCaseInsensitiveContains(selectedDirective.rawValue) })
        }
    }

    public var body: some View {
        ZStack {
            CyberTheme.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Istituzionale
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hub Normativo & Compliance")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Quadro regolatorio italiano ed europeo per CISO e DPO")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(CyberTheme.orangePrimary)
                    }
                    .padding(.top, 10)

                    // Selettore Direttiva (Segmented Tab a Pills)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DirectiveType.allCases) { directive in
                                let isSelected = directive == selectedDirective
                                Button {
                                    HapticManager.shared.selection()
                                    withAnimation(CyberTheme.quickSpring) {
                                        selectedDirective = directive
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: directive.icon)
                                            .font(.system(size: 12))
                                        Text(directive.rawValue)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                    }
                                    .foregroundStyle(isSelected ? .black : .white.opacity(0.75))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.06))
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? CyberTheme.orangePrimary : Color.white.opacity(0.12), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Scheda Approfondita della Direttiva Selezionata
                    directiveDetailCard(for: selectedDirective)

                    // Box Checklist Readiness Veloce
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "checklist.checked")
                                    .foregroundStyle(CyberTheme.orangePrimary)
                                Text("READINESS AUDIT RAPIDO")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)
                            }

                            Spacer()

                            Text("\(readinessScore)% Conforme")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(readinessScore >= 75 ? Color.green : CyberTheme.orangePrimary)
                        }

                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(readinessScore >= 75 ? Color.green : CyberTheme.orangePrimary)
                                    .frame(width: geo.size.width * CGFloat(readinessScore) / 100, height: 6)
                                    .animation(.spring, value: readinessScore)
                            }
                        }
                        .frame(height: 6)

                        VStack(spacing: 10) {
                            checklistToggle(
                                title: "Censimento Portale ACN",
                                subtitle: "Verificato se l'ente ricade tra soggetti essenziali/importanti",
                                isOn: $checkAcnRegistered
                            )
                            checklistToggle(
                                title: "Procedura Alert 24 Ore",
                                subtitle: "Canale di comunicazione urgente verso CSIRT Italia configurato",
                                isOn: $checkIncident24h
                            )
                            checklistToggle(
                                title: "Mappatura Terze Parti & Fornitori",
                                subtitle: "Contratti ICT conformi a requisiti NIS2 / DORA e Golden Power",
                                isOn: $checkSupplyChain
                            )
                            checklistToggle(
                                title: "MFA & Backup Immutabili",
                                subtitle: "Doppio fattore su accessi privilegiati e copie offline isolate",
                                isOn: $checkMfaBackup
                            )
                        }
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Ultimi Provvedimenti & Articoli Correlati
                    if !relevantArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BOLLETTINI & AGGIORNAMENTI: \(selectedDirective.rawValue)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.65))

                            ForEach(relevantArticles.prefix(3)) { article in
                                Button {
                                    HapticManager.shared.impact(.light)
                                    selectedArticle = article
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(CyberTheme.orangePrimary)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.titleIt)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)

                                            HStack(spacing: 6) {
                                                Text(article.sourceName)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(CyberTheme.orangeLight)
                                                Text("•")
                                                    .foregroundStyle(.white.opacity(0.3))
                                                Text(article.formattedRelativeTime)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.3))
                                            .padding(.top, 6)
                                    }
                                    .padding(14)
                                    .glassmorphic(cornerRadius: 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
    }

    // MARK: - Componente Card Direttiva
    @ViewBuilder
    private func directiveDetailCard(for type: DirectiveType) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(type.lawReference)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Text("IN VIGORE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(CyberTheme.orangePrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CyberTheme.orangePrimary.opacity(0.15))
                            .overlay(Capsule().stroke(CyberTheme.orangePrimary.opacity(0.4), lineWidth: 1))
                    )
            }

            Divider()
                .background(Color.white.opacity(0.08))

            switch type {
            case .nis2:
                directiveRow(icon: "clock.badge.exclamationmark", title: "Tempistiche di Notifica ad ACN", desc: "Pre-notifica entro 24 ore dall'incidente significativo, notifica completa entro 72 ore, relazione conclusiva entro 1 mese.")
                directiveRow(icon: "person.3.sequence.fill", title: "Soggetti Impattati", desc: "Soggetti Essenziali e Importanti nei settori energia, trasporti, sanità, cloud, PA e fornitori di servizi digitali.")
                directiveRow(icon: "exclamationmark.triangle.fill", title: "Sanzioni & Responsabilità", desc: "Fino a 10M€ o 2% del fatturato mondiale annuo. Responsabilità diretta estesa agli organi di vertice aziendali.")

            case .goldenPower:
                directiveRow(icon: "lock.shield.fill", title: "Perimetro di Sicurezza", desc: "Poteri speciali del Governo su asset strategici nazionali: reti 5G, datacenter, semiconduttori e intelligenza artificiale.")
                directiveRow(icon: "doc.badge.gearshape.fill", title: "Obbligo di Notifica Preventiva", desc: "Obbligo per le aziende di notificare preventivamente alla Presidenza del CdM contratti con vendor extra-UE prima dell'acquisto.")
                directiveRow(icon: "checkmark.shield.fill", title: "Verifiche CVCN", desc: "Test di sicurezza e collaudo hardware/software condotti dal Centro Valutazione e Certificazione Nazionale di ACN.")

            case .dora:
                directiveRow(icon: "banknote.fill", title: "Resilienza Operativa Finanziaria", desc: "Regolamento UE vincolante per banche, assicurazioni, fondi e fornitori ICT critici nel mercato unico europeo.")
                directiveRow(icon: "cpu.fill", title: "Test TLPT Avanzati", desc: "Obbligo periodico di Threat-Led Penetration Testing simulando attacchi realistici avanzati (TIBER-EU).")
                directiveRow(icon: "network", title: "Rischio Terze Parti (Third-Party Risk)", desc: "Sorveglianza continua su cloud provider e fornitori critici di software con diritto di ispezione diretta.")

            case .iso27001:
                directiveRow(icon: "shield.lefthalf.filled", title: "Nuova Edizione ISO/IEC 27001:2022", desc: "Annex A aggiornato a 93 controlli suddivisi in 4 temi chiave (Organizzativi, Persone, Fisici e Tecnologici).")
                directiveRow(icon: "antenna.radiowaves.left.and.right", title: "Controllo 5.7: Threat Intelligence", desc: "Obbligo di raccogliere e analizzare informazioni sulle minacce informatiche per prevenire incidenti.")
                directiveRow(icon: "cloud.fill", title: "Controllo 5.23: Sicurezza Cloud", desc: "Requisiti stringenti per l'acquisizione, l'uso e la cessazione dei servizi cloud aziendali.")
            }
        }
        .padding(18)
        .glassmorphic(cornerRadius: 22)
    }

    private func directiveRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(CyberTheme.orangePrimary)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(desc)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(2)
            }
        }
    }

    private func checklistToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .tint(CyberTheme.orangePrimary)
    }
}
