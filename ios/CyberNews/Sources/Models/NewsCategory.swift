import SwiftUI

public enum NewsCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case all               = "ALL"
    case nis2GoldenPower   = "NIS2_GOLDEN_POWER"
    case vulnerabilita     = "VULNERABILITA_ZERODAY"
    case ransomware        = "RANSOMWARE_ATTACCHI"
    case complianceIso     = "COMPLIANCE_ISO"
    case threatIntel       = "THREAT_INTEL"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all:               return "Tutte"
        case .nis2GoldenPower:   return "NIS2 & Golden Power"
        case .vulnerabilita:     return "Zero-Day & Bug"
        case .ransomware:        return "Ransomware"
        case .complianceIso:     return "ISO 27001 & DORA"
        case .threatIntel:       return "Threat Intel"
        }
    }

    public var iconName: String {
        switch self {
        case .all:               return "sparkles"
        case .nis2GoldenPower:   return "building.columns.fill"
        case .vulnerabilita:     return "ladybug.fill"
        case .ransomware:        return "lock.trianglebadge.exclamationmark.fill"
        case .complianceIso:     return "checkmark.seal.fill"
        case .threatIntel:       return "radar"
        }
    }
}
