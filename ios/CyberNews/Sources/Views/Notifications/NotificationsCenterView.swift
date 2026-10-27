import SwiftUI

public struct NotificationsCenterView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var filterCriticalOnly: Bool = false
    @State private var showingClearConfirmation: Bool = false

    public init() {}

    private var filteredList: [DeliveredNotification] {
        if filterCriticalOnly {
            return notificationManager.notifications.filter { $0.threatLevel == .critico }
        }
        return notificationManager.notifications
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CyberTheme.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header con Filtro Rapido
                    HStack {
                        // Toggle Tutte vs Solo Critiche
                        HStack(spacing: 8) {
                            Button {
                                HapticManager.shared.selection()
                                filterCriticalOnly = false
                            } label: {
                                Text("Tutte (\(notificationManager.notifications.count))")
                                    .font(.system(size: 12, weight: !filterCriticalOnly ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(!filterCriticalOnly ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(!filterCriticalOnly ? CyberTheme.orangePrimary : Color.white.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                HapticManager.shared.selection()
                                filterCriticalOnly = true
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(CyberTheme.threatCritico)
                                        .frame(width: 6, height: 6)
                                    Text("Solo Critiche")
                                        .font(.system(size: 12, weight: filterCriticalOnly ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(filterCriticalOnly ? .white : .white.opacity(0.7))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(filterCriticalOnly ? CyberTheme.threatCritico.opacity(0.8) : Color.white.opacity(0.06))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Segna tutte lette
                        if notificationManager.unreadCount > 0 {
                            Button {
                                HapticManager.shared.impact(.light)
                                notificationManager.markAllAsRead()
                            } label: {
                                Text("Segna lette")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(CyberTheme.orangePrimary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    // Lista Notifiche
                    if filteredList.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(.white.opacity(0.2))

                            Text("Nessuna notifica ricevuta")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))

                            Text("Le notifiche push per Zero-Day e allarmi ACN compariranno automaticamente qui non appena rilevate.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Button {
                                HapticManager.shared.notification(.success)
                                notificationManager.sendTestNotification { _, _, _ in }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 11))
                                    Text("Invia Notifica di Prova")
                                }
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(CyberTheme.orangePrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(CyberTheme.orangePrimary.opacity(0.12))
                                        .overlay(Capsule().stroke(CyberTheme.orangePrimary.opacity(0.3), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)

                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredList) { item in
                                    NotificationRowView(notification: item) {
                                        notificationManager.markAsRead(id: item.id)
                                    } onDelete: {
                                        notificationManager.deleteNotification(id: item.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Centro Notifiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !notificationManager.notifications.isEmpty {
                        Button {
                            showingClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .confirmationDialog("Svuotare lo storico notifiche?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Elimina tutte le notifiche", role: .destructive) {
                    HapticManager.shared.notification(.warning)
                    notificationManager.clearHistory()
                }
                Button("Annulla", role: .cancel) {}
            }
        }
    }
}

// MARK: - Singola Riga Notifica
struct NotificationRowView: View {
    let notification: DeliveredNotification
    let onMarkRead: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Indicatore Letto/Non Letto o Icona Rischio
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill((notification.threatLevel == .critico ? CyberTheme.threatCritico : CyberTheme.orangePrimary).opacity(0.18))
                        .frame(width: 36, height: 36)

                    Image(systemName: notification.threatLevel == .critico ? "exclamationmark.triangle.fill" : "bell.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(notification.threatLevel == .critico ? CyberTheme.threatCritico : CyberTheme.orangePrimary)
                }

                if !notification.isRead {
                    Circle()
                        .fill(CyberTheme.orangePrimary)
                        .frame(width: 7, height: 7)
                }
            }

            // Testo Notifica
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Text(notification.formattedTime)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Text(notification.subtitle)
                    .font(.system(size: 14, weight: notification.isRead ? .medium : .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(notification.body)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            // Tasto elimina singolo
            Button {
                HapticManager.shared.impact(.light)
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassmorphic(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    !notification.isRead ? CyberTheme.orangePrimary.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
        .onTapGesture {
            onMarkRead()
        }
    }
}
