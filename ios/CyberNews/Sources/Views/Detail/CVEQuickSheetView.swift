import SwiftUI
import SafariServices

public struct CVEQuickSheetView: View {
    public let cveId: String

    @Environment(\.dismiss) private var dismiss
    @State private var record: CVERecord? = nil
    @State private var isLoading = true
    @State private var copiedId = false
    @State private var copiedVector = false
    @State private var activeSafariURL: URL? = nil

    public init(cveId: String) {
        self.cveId = cveId
    }

    private var severityColor: Color {
        guard let score = record?.cvssScore else { return CyberTheme.threatInformativo }
        if score >= 9.0 { return CyberTheme.threatCritico }
        if score >= 7.0 { return CyberTheme.threatAlto }
        if score >= 4.0 { return CyberTheme.threatMedio }
        return CyberTheme.threatInformativo
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CyberTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header Identificativo CVE
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 13))
                                        .foregroundStyle(CyberTheme.orangePrimary)

                                    Text("NVD NIST • MITRE CVE")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .foregroundStyle(CyberTheme.orangePrimary)
                                }

                                Text(cveId)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }

                            Spacer()

                            // Tasto Copia Rapida ID
                            Button {
                                UIPasteboard.general.string = cveId
                                HapticManager.shared.notification(.success)
                                withAnimation {
                                    copiedId = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        copiedId = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: copiedId ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    Text(copiedId ? "Copiato!" : "Copia")
                                }
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(copiedId ? Color.green : CyberTheme.cyanPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(CyberTheme.cyanPrimary.opacity(0.12))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)

                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(CyberTheme.orangePrimary)
                                Text("Interrogazione database MITRE CVE in corso...")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else if let rec = record {
                            // Banner Allerta CISA KEV (Exploit Attivo in the Wild)
                            if rec.isKnownExploited {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.black)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("PRESENTE NEL CATALOGO CISA KEV")
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.black)
                                        Text("Sfruttamento attivo confermato in the wild")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.black.opacity(0.85))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(CyberTheme.threatCritico)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            // Card Metriche CVSS
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("CVSS BASE SCORE")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.55))

                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text(rec.formattedScore)
                                                .font(.system(size: 32, weight: .black, design: .rounded))
                                                .foregroundStyle(severityColor)

                                            if let sev = rec.cvssSeverity {
                                                Text(sev)
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(severityColor.opacity(0.18))
                                                    .foregroundStyle(severityColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }

                                    Spacer()

                                    // Software o Vendor Impattato
                                    if let prod = rec.product {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("SISTEMA IMPATTATO")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.5))

                                            Text(prod)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)

                                            if let vendor = rec.vendor {
                                                Text(vendor)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.white.opacity(0.6))
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }

                                // Vector String
                                if let vector = rec.vectorString, !vector.isEmpty {
                                    Divider()
                                        .background(Color.white.opacity(0.08))

                                    HStack(spacing: 8) {
                                        Text(vector)
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundStyle(CyberTheme.cyanPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Spacer()

                                        Button {
                                            UIPasteboard.general.string = vector
                                            HapticManager.shared.impact(.light)
                                            withAnimation {
                                                copiedVector = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                withAnimation {
                                                    copiedVector = false
                                                }
                                            }
                                        } label: {
                                            Image(systemName: copiedVector ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 11))
                                                .foregroundStyle(copiedVector ? Color.green : .white.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(16)
                            .glassmorphic(cornerRadius: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(severityColor.opacity(0.35), lineWidth: 1)
                            )

                            // Titolo o Descrizione Tecnica
                            if let title = rec.title, !title.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("OGGETTO DELLA VULNERABILITÀ")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))

                                    Text(title)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineSpacing(2)
                                }
                                .padding(16)
                                .glassmorphic(cornerRadius: 18)
                            }

                            if let desc = rec.description, !desc.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("DESCRIZIONE TECNICA MITRE / NVD")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))

                                    Text(desc)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(3)
                                }
                                .padding(16)
                                .glassmorphic(cornerRadius: 18)
                            }

                            // Bottoni di Consultazione Istituzionali
                            VStack(spacing: 10) {
                                Text("CONSULTA ARCHIVI UFFICIALI")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // NIST NVD
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    activeSafariURL = CVEService.shared.nvdURL(for: cveId)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("Apri Bollettino NIST NVD")
                                        Spacer()
                                        Text("nvd.nist.gov")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(CyberTheme.surfaceCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                // MITRE CVE.org
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    activeSafariURL = CVEService.shared.mitreURL(for: cveId)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("Apri Scheda Ufficiale CVE.org")
                                        Spacer()
                                        Text("cve.org")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(CyberTheme.surfaceCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 4)
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .sheet(item: $activeSafariURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
            .task {
                let fetched = await CVEService.shared.fetchCVEDetails(cveId: cveId)
                withAnimation {
                    self.record = fetched
                    self.isLoading = false
                }
            }
        }
    }
}

// URL extension per Identifiable sheet
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
