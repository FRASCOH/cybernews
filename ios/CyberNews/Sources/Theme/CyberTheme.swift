import SwiftUI

// MARK: - CyberTheme
/// Palette colori, gradienti e costanti di stile per CyberNews
public enum CyberTheme {
    // MARK: - Colors
    /// Cyber Orange primario per logo, accenti e call-to-action
    public static let orangePrimary = Color(red: 1.0, green: 0.42, blue: 0.0)      // #FF6B00
    public static let orangeLight   = Color(red: 1.0, green: 0.53, blue: 0.15)     // #FF8726
    public static let orangeDark    = Color(red: 0.88, green: 0.32, blue: 0.0)     // #E05200
    public static let orangeGlow    = Color(red: 1.0, green: 0.42, blue: 0.0).opacity(0.35)

    /// Cyber Cyan / Neon per notizie nuove (non lette)
    public static let cyanPrimary   = Color(red: 0.0, green: 0.88, blue: 1.0)       // #00E0FF
    public static let cyanLight     = Color(red: 0.40, green: 0.94, blue: 1.0)     // #66F0FF
    public static let cyanDark      = Color(red: 0.0, green: 0.55, blue: 0.85)      // #008CD9
    public static let cyanGlow      = Color(red: 0.0, green: 0.88, blue: 1.0).opacity(0.25)

    /// Sfondo profondo Minimal Dark
    public static let backgroundDark = Color(red: 0.035, green: 0.035, blue: 0.045) // #09090C
    public static let surfaceDark    = Color(red: 0.07, green: 0.07, blue: 0.09)     // #121217
    public static let surfaceCard    = Color(red: 0.10, green: 0.10, blue: 0.13)     // #1A1A21

    /// Livelli di Rischio (Cyber Threat Colors)
    public static let threatCritico     = Color(red: 1.0, green: 0.23, blue: 0.19)  // Rosso Neon
    public static let threatAlto        = Color(red: 1.0, green: 0.58, blue: 0.0)   // Arancio Intenso
    public static let threatMedio       = Color(red: 1.0, green: 0.80, blue: 0.0)   // Giallo Cyber
    public static let threatInformativo = Color(red: 0.0, green: 0.48, blue: 1.0)   // Blu Elettrico

    // MARK: - Gradients
    public static let orangeGradient = LinearGradient(
        colors: [orangeLight, orangePrimary, orangeDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let glassBorderGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.18),
            Color.white.opacity(0.04),
            orangePrimary.opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let activePillGradient = LinearGradient(
        colors: [
            orangePrimary.opacity(0.25),
            orangeDark.opacity(0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let unreadCardGradient = LinearGradient(
        colors: [
            cyanLight.opacity(0.95),
            cyanPrimary.opacity(0.65),
            cyanDark.opacity(0.25),
            Color.white.opacity(0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Animations
    public static let smoothSpring = Animation.spring(response: 0.36, dampingFraction: 0.78, blendDuration: 0)
    public static let quickSpring  = Animation.spring(response: 0.25, dampingFraction: 0.70, blendDuration: 0)
}

// MARK: - Glassmorphic Card ViewModifier
public struct GlassmorphicModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var strokeColor: Color = Color.white.opacity(0.10)
    var isInteractive: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                CyberTheme.glassBorderGradient,
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
            )
    }
}

public extension View {
    func glassmorphic(cornerRadius: CGFloat = 22, strokeColor: Color = Color.white.opacity(0.10)) -> some View {
        self.modifier(GlassmorphicModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
