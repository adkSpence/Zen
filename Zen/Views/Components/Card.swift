import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
    }
}

struct CardHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.cardTitle())
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing { trailing }
        }
    }
}
