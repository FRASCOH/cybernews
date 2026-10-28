import SwiftUI
import UIKit

public struct SettingsView: View {
    @AppStorage("push_notifications_enabled") private var pushNotificationsEnabled: Bool = true
    @AppStorage("notify_all_news") private var notifyAllNews: Bool = true
    @AppStorage("notify_critical") private var notifyCritical: Bool = true
    @AppStorage("notify_governance") private var notifyGovernance: Bool = true
    @AppStorage("apns_device_token") private var apnsDeviceToken: String = ""
    @AppStorage("apns_registration_error") private var apnsError: String = ""

    @State private var showingTestSentAlert = false
    @State private var testAlertTitle = ""
    @State private var testAlertMessage = ""
    @State private var isPermissionDenied = false
    @State private var copiedToken = false
    @State private var isRegistering = false

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
                            }
                        }
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Card Apple APNs Direct
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 16))
                                .foregroundStyle(CyberTheme.cyanPrimary)

                            Text("APPLE PUSH (APNs DIRETTO)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(CyberTheme.cyanPrimary)

                            Spacer()

                            if !apnsDeviceToken.isEmpty {
                                Text("ATTIVO")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(Color.green)
                                    .clipShape(Capsule())
                            }
                        }

                        if !apnsDeviceToken.isEmpty {
                            Text("Dispositivo registrato con successo ad Apple APNs. Il token push per il tuo iPhone è pronto:")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineSpacing(2)

                            Text(apnsDeviceToken)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(CyberTheme.cyanPrimary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Button {
                                UIPasteboard.general.string = apnsDeviceToken
                                HapticManager.shared.notification(.success)
                                withAnimation {
                                    copiedToken = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation {
                                        copiedToken = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: copiedToken ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    Text(copiedToken ? "Token Copiato negli Appunti!" : "Copia Token APNs iPhone")
                                }
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(copiedToken ? Color.green : CyberTheme.cyanPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(CyberTheme.cyanPrimary.opacity(0.12))
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("In attesa del token da Apple... Assicurati che l'app sia avviata su un iPhone fisico collegato ad internet.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineSpacing(2)

                                if !apnsError.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Dettaglio stato:")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(CyberTheme.threatAlto)
                                        Text(apnsError)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(CyberTheme.threatAlto.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }

                                Button {
                                    HapticManager.shared.impact(.medium)
                                    isRegistering = true
                                    NotificationManager.shared.requestAuthorization { _ in
                                        DispatchQueue.main.async {
                                            UIApplication.shared.registerForRemoteNotifications()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                isRegistering = false
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isRegistering {
                                            ProgressView()
                                                .tint(CyberTheme.cyanPrimary)
                                        } else {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                        }
                                        Text(isRegistering ? "Connessione ad Apple in corso..." : "Richiedi Registrazione Token APNs")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.cyanPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(CyberTheme.cyanPrimary.opacity(0.12))
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
