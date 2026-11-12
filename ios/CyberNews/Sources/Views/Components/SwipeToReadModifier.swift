import SwiftUI
import UIKit

/// Modificatore per abilitare lo swipe orizzontale (destra o sinistra) su una card di notizia
/// senza MAI bloccare lo scroll verticale nativo di iOS a 120Hz.
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
            // Sfondo visibile solo durante il trascinamento orizzontale
            if offset != 0 {
                swipeActionBackground
            }

            // Card in primo piano
            content
                .offset(x: offset)
                .overlay(
                    HorizontalPanView(
                        onChanged: { deltaX in
                            let horizontal = deltaX
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
                        },
                        onEnded: { finalX in
                            let passed = abs(finalX) >= threshold

                            if passed {
                                HapticManager.shared.notification(.success)
                                // Esegui la modifica di stato senza avviare transazioni di spring globali
                                onReadToggle()
                            }

                            // Ritorno rapido in 180ms senza congelare lo scroll
                            withAnimation(.easeOut(duration: 0.18)) {
                                offset = 0
                                hasTriggeredThresholdHaptic = false
                            }
                        }
                    )
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

// MARK: - UIKit Pan Gesture Recognizer per discriminare orizzontale vs verticale
private struct HorizontalPanView: UIViewRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (CGFloat) -> Void

    func makeUIView(context: Context) -> PanTouchView {
        let view = PanTouchView()
        view.backgroundColor = .clear
        view.isOpaque = false

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ uiView: PanTouchView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat) -> Void

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .changed:
                onChanged(translation.x)
            case .ended, .cancelled:
                onEnded(translation.x)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view else { return false }
            let velocity = pan.velocity(in: view)
            // Attiva il gesto SOLO se è prevalentemente orizzontale.
            // Se l'utente scorre in verticale, ritorna FALSE immediatamente:
            // lo ScrollView di iOS scorre subito senza alcun lag o blocco di 2-3 secondi!
            return abs(velocity.x) > abs(velocity.y) * 1.25 && abs(velocity.x) > 20
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Non interferisce con lo scroll
            return false
        }
    }
}

/// Sottoclasse UIView che non intercetta i tap puri, lasciandoli passare ai pulsanti SwiftUI
private class PanTouchView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Se c'è un tocco, permette al pan recognizer di valutarlo
        return true
    }
}

public extension View {
    func swipeToRead(isRead: Bool, onReadToggle: @escaping () -> Void) -> some View {
        self.modifier(SwipeToReadModifier(isRead: isRead, onReadToggle: onReadToggle))
    }
}
