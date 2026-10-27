import SwiftUI

public struct CyberLogoView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            // Testo Logo con tipografia dinamica e arancione Cyber
            HStack(spacing: 0) {
                Text("Cyber")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("News")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(CyberTheme.orangeGradient)
            }

            // Radar Pulse Dot (Segnale di monitoraggio attivo in tempo reale)
            Circle()
                .fill(CyberTheme.orangePrimary)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.25 : 0.85)
                .opacity(isPulsing ? 1.0 : 0.45)
                .shadow(color: CyberTheme.orangePrimary.opacity(0.8), radius: 6, x: 0, y: 0)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .onAppear {
            isPulsing = true
        }
    }
}
