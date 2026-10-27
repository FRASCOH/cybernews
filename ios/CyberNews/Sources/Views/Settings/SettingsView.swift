import SwiftUI
import UIKit

public struct SettingsView: View {
    @AppStorage("push_notifications_enabled") private var pushNotificationsEnabled: Bool = true
    @AppStorage("notify_all_news") private var notifyAllNews: Bool = true
    @AppStorage("notify_critical") private var notifyCritical: Bool = true
    @AppStorage("notify_governance") private var notifyGovernance: Bool = true

    @State private var showingTestSentAlert = false
    @State private var testAlertTitle = ""
    @State private var testAlertMessage = ""
    @State private var isPermissionDenied = false
    @State private var showNotificationsCenter = false

    public init() {}

    public var body: some View {
        ZStack {
            CyberTheme.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Impostazioni")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Notifiche Push & Preferenze")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(CyberTheme.orangePrimary)
                    }
                    .padding(.top, 10)

                    // Card Notifiche Push in Tempo Reale
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(CyberTheme.orangePrimary)

                            Text("NOTIFICHE PUSH IN TEMPO REALE")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(CyberTheme.orangePrimary)
                        }

                        VStack(spacing: 14) {
                            // Toggle Principale
                            Toggle(isOn: $pushNotificationsEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notifiche Push Attive")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("Avviso prioritario con audio e vibrazione aptica")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .tint(CyberTheme.orangePrimary)

                            if pushNotificationsEnabled {
                                Divider()
                                    .background(Color.white.opacity(0.08))

                                // Filtri Notifica
                                Toggle(isOn: $notifyAllNews) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tutte le Nuove Notizie")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text("Ricevi un avviso per ogni articolo pubblicato")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .tint(CyberTheme.orangePrimary)

                                Toggle(isOn: $notifyCritical) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Zero-Day & Allarmi Critici")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text("Notifiche prioritarie ad alto volume sonoro")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .tint(CyberTheme.orangePrimary)

                                Toggle(isOn: $notifyGovernance) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Alert ACN & Normative (NIS2)")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text("Aggiornamenti su direttive NIS2 e Golden Power")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .tint(CyberTheme.orangePrimary)

                                // Tasto di Prova Notifica
                                Button {
                                    HapticManager.shared.notification(.success)
                                    NotificationManager.shared.sendTestNotification { success, message, isDenied in
                                        testAlertTitle = success ? "Notifica Inviata! 🔔" : "Permessi Richiesti ⚠️"
                                        testAlertMessage = message
                                        isPermissionDenied = isDenied
                                        showingTestSentAlert = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 12))
                                        Text("Invia Notifica di Prova Adesso")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(CyberTheme.orangePrimary.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(CyberTheme.orangePrimary.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 6)

                                // Tasto Apri Centro Notifiche
                                Button {
                                    HapticManager.shared.impact(.light)
                                    showNotificationsCenter = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.badge.fill")
                                            .font(.system(size: 12))
                                        Text("Visualizza Cronologia Notifiche Ricevute")
                                    }
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Card Architettura di Sicurezza
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(CyberTheme.orangePrimary)

                            Text("SICUREZZA & ZERO-KEY")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(CyberTheme.orangePrimary)
                        }

                        Text("L'app legge le notizie direttamente dal database cloud sicuro protetto da Row-Level Security (RLS). Nessuna chiave privata o credenziale Gemini è archiviata sull'iPhone.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Fonti Monitorate
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FONTI UFFICIALI ATTIVE (20)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("ACN, CSIRT Italia, CERT-AGID, Golden Power (CdM), Gazzetta Ufficiale, Portale NIS2, Red Hot Cyber, Cybersecurity360, Agenda Digitale, EDPB, Garante Privacy, EBA (DORA), ISO/IEC 27001, NIST CSF 2.0, ENISA, CISA Alerts/KEV, BleepingComputer, The Hacker News, SANS ISC, SecurityWeek.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Info Versione
                    VStack(alignment: .center, spacing: 4) {
                        Text("CyberNews for iOS • v1.0.0")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("Made with SwiftUI & Gemini AI")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showNotificationsCenter) {
            NotificationsCenterView()
        }
        .alert(testAlertTitle, isPresented: $showingTestSentAlert) {
            if isPermissionDenied {
                Button("Apri Impostazioni iPhone") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Annulla", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(testAlertMessage)
        }
    }
}
