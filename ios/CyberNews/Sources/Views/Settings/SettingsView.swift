import SwiftUI

public struct SettingsView: View {
    @AppStorage("supabase_url") private var supabaseURL: String = ""
    @AppStorage("supabase_anon_key") private var supabaseAnonKey: String = ""
    @State private var showingSavedAlert = false

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

                        Text("Sicurezza & Configurazione")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(CyberTheme.orangePrimary)
                    }
                    .padding(.top, 10)

                    // Card Architettura di Sicurezza
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(CyberTheme.orangePrimary)

                            Text("SICUREZZA ZERO-KEY ON DEVICE")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(CyberTheme.orangePrimary)
                        }

                        Text("Questa app non memorizza alcuna chiave API privata di Gemini. L'elaborazione con AI avviene in un ambiente protetto sul cloud, garantendo l'assoluta protezione da furti di credenziali o reverse engineering.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Collegamento Database Supabase (Opzionale)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CONNESSIONE CLOUD (SUPABASE)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Project URL")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

                                TextField("https://xyz.supabase.co", text: $supabaseURL)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Anon Public Key")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

                                SecureField("eyJhbGciOi...", text: $supabaseAnonKey)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                            }

                            Button {
                                HapticManager.shared.notification(.success)
                                NewsAPIService.shared.supabaseURL = supabaseURL
                                NewsAPIService.shared.supabaseAnonKey = supabaseAnonKey
                                showingSavedAlert = true
                            } label: {
                                Text("Salva e Connetti")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(CyberTheme.orangeGradient)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    .padding(18)
                    .glassmorphic(cornerRadius: 20)

                    // Fonti Monitorate
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FONTI UFFICIALI ATTIVE (19)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("ACN, CSIRT Italia, CERT-AGID, Golden Power (CdM), Gazzetta Ufficiale, Portale NIS2, Cybersecurity360, Agenda Digitale, EDPB, Garante Privacy, EBA (DORA), ISO/IEC 27001, NIST CSF 2.0, ENISA, CISA Alerts/KEV, BleepingComputer, The Hacker News, SANS ISC, SecurityWeek.")
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

                        Text("Made with SwiftUI & Gemini 2.0 Flash")
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
        .alert("Configurazione Salvata", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("L'app tenterà di connettersi al database Supabase al prossimo aggiornamento.")
        }
    }
}
