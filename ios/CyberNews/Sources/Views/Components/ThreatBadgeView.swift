import SwiftUI

public struct ThreatBadgeView: View {
    public let level: ThreatLevel
    public var compact: Bool = false

    public init(level: ThreatLevel, compact: Bool = false) {
        self.level = level
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: level.iconName)
                .font(.system(size: compact ? 10 : 12, weight: .bold))

            Text(level.title)
                .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(
            Capsule()
                .fill(level.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(level.color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
