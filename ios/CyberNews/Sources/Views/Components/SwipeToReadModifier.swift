import SwiftUI

/// Modificatore per abilitare lo swipe orizzontale (destra o sinistra) su una card di notizia
/// isolato per ciascuna card, senza toccare le notizie adiacenti e senza bloccare lo scroll.
public struct SwipeToReadModifier: ViewModifier {
    public let isRead: Bool
    public let onReadToggle: () -> Void

    @State private var offset: CGFloat = 0
    @State private var hasTriggeredThresholdHaptic: Bool = false

    private let threshold: CGFloat = 75
    private let maxDrag: CGFloat = 110

    public init(isRead: Bool, onReadToggle: @escaping () -> Void) {
        self.isRead = isRead
        self.onReadToggle = onReadToggle
    }

    public func body(content: Content) -> some View {
        ZStack {
            // Sfondo visibile solo durante il trascinamento di QUESTA specifica card
            if offset != 0 {
                swipeActionBackground
            }

            // Card in primo piano
            content
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height

                            // Considera il gesto SOLO se è prevalentemente orizzontale
                            guard abs(horizontal) > abs(vertical) * 1.2 else { return }

                            if abs(horizontal) > maxDrag {
                                let sign: CGFloat = horizontal > 0 ? 1 : -1
                                offset = sign * (maxDrag + (abs(horizontal) - maxDrag) * 0.25)
                            } else {
                                offset = horizontal
                            }

                            if abs(horizontal) >= threshold && !hasTriggeredThresholdHaptic {
                                hasTriggeredThresholdHaptic = true
                                HapticManager.shared.impact(.medium)
                            } else if abs(horizontal) < threshold {
                                hasTriggeredThresholdHaptic = false
                            }
                        }
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let passed = abs(horizontal) >= threshold

                            if passed {
                                HapticManager.shared.notification(.success)
                                onReadToggle()
                            }

                            // Ritorno rapido in 180ms senza congelare lo scroll
                            withAnimation(.easeOut(duration: 0.18)) {
                                offset = 0
                                hasTriggeredThresholdHaptic = false
                            }
                        }
                )
        }
    }

    // MARK: - Sfondo di Azione con Grafica Cyber
    private var swipeActionBackground: some View {
        let isSwipingRight = offset > 0
        let reachedThreshold = abs(offset) >= threshold

        return RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isSwipingRight
                        ? [CyberTheme.cyanPrimary.opacity(reachedThreshold ? 0.28 : 0.16), Color.clear]
                        : [Color.clear, CyberTheme.cyanPrimary.opacity(reachedThreshold ? 0.28 : 0.16)],
                    startPoint: isSwipingRight ? .leading : .trailing,
                    endPoint: isSwipingRight ? .trailing : .leading
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(CyberTheme.cyanPrimary.opacity(reachedThreshold ? 0.45 : 0.20), lineWidth: 1.2)
            )
            .overlay(alignment: isSwipingRight ? .leading : .trailing) {
                HStack(spacing: 8) {
                    if !isSwipingRight {
                        Text(isRead ? "Segna da leggere" : "Segna come letta")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(CyberTheme.cyanPrimary)
                    }

                    Image(systemName: isRead ? "envelope.badge.fill" : "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(CyberTheme.cyanPrimary)
                        .scaleEffect(reachedThreshold ? 1.2 : 1.0)
                        .shadow(color: CyberTheme.cyanPrimary.opacity(reachedThreshold ? 0.7 : 0.2), radius: 6)

                    if isSwipingRight {
                        Text(isRead ? "Segna da leggere" : "Segna come letta")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(CyberTheme.cyanPrimary)
                    }
                }
                .padding(.horizontal, 22)
            }
    }
}

public extension View {
    func swipeToRead(isRead: Bool, onReadToggle: @escaping () -> Void) -> some View {
        self.modifier(SwipeToReadModifier(isRead: isRead, onReadToggle: onReadToggle))
    }
}
