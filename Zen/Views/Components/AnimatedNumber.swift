import SwiftUI

struct AnimatedNumber: View {
    let value: String

    var body: some View {
        Text(value)
            .contentTransition(.numericText(countsDown: true))
            .animation(.focusDefault, value: value)
    }
}

/// Formats seconds into MM:SS
func formatTime(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded(.up)))
    let m = total / 60
    let s = total % 60
    return String(format: "%02d:%02d", m, s)
}
