import SwiftUI

extension Font {
    static func timerDigits(size: CGFloat = 56) -> Font {
        .system(size: size, weight: .light, design: .monospaced)
    }
    static func displayRounded(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func cardTitle() -> Font {
        .system(size: 13, weight: .semibold, design: .rounded)
    }
}
