import SwiftUI

struct CircularTimerRing: View {
    let progress: Double        // 0…1
    let color: Color
    let diameter: CGFloat

    private let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.modeTransition, value: color)
        }
        .frame(width: diameter, height: diameter)
    }
}
