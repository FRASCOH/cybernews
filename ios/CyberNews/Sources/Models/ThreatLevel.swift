import SwiftUI

public enum ThreatLevel: String, Codable, CaseIterable {
    case critico     = "CRITICO"
    case alto        = "ALTO"
    case medio       = "MEDIO"
    case informativo = "INFORMATIVO"

    public var title: String {
        switch self {
        case .critico:     return "CRITICO"
        case .alto:        return "ALTO"
        case .medio:       return "MEDIO"
        case .informativo: return "INFO"
        }
    }

    public var color: Color {
        switch self {
        case .critico:     return CyberTheme.threatCritico
        case .alto:        return CyberTheme.threatAlto
        case .medio:       return CyberTheme.threatMedio
        case .informativo: return CyberTheme.threatInformativo
        }
    }

    public var iconName: String {
        switch self {
        case .critico:     return "exclamationmark.shield.fill"
        case .alto:        return "shield.lefthalf.filled"
        case .medio:       return "exclamationmark.circle.fill"
        case .informativo: return "info.circle.fill"
        }
    }
}
