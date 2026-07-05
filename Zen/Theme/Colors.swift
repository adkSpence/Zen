import SwiftUI

extension Color {
    static let bgBase = Color(hex: "0E0E10")
    static let textPrimary = Color(hex: "F2F2F4")
    static let textSecondary = Color(hex: "A0A0A8")
    static let accentFocus = Color(hex: "F2A65A")
    static let accentBreak = Color(hex: "7DB7C9")
    static let accentBreakLong = Color(hex: "5B92A8")
    static let accentStreakStart = Color(hex: "FF8A3D")
    static let accentStreakEnd = Color(hex: "F2A65A")
    static let cardBorder = Color.white.opacity(0.06)
    static let cardBorderLight = Color.black.opacity(0.04)

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
