import SwiftUI

struct FeatureTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .imageScale(.medium)
                    .symbolEffect(.pulse, options: .repeating, value: animate && !reduceMotion)
            }

            Text(title)                 // one word, never hyphenate
                .font(AppFontV3.h2())
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .allowsTightening(true)

            Text(subtitle)              // wrap up to two lines, no clipping
                .font(AppFontV3.caption())
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: Layout.tileMinHeight, alignment: .topLeading)
        .tileSurface()
        .contentShape(Rectangle())
        .onAppear { animate = true }
    }
} 