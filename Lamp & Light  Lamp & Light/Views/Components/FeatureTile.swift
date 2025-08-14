import SwiftUI

struct FeatureTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    var action: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var animate = false

    var body: some View {
        Button {
            Haptics.tap()
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle().fill(tint.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                        .imageScale(.medium)
                        .symbolEffect(.pulse, options: .repeating, value: animate && !reduceMotion)
                }

                // Keep on one line
                Text(title)
                    .font(AppFontV3.h2())
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)

                // Wrap up to two lines, never clip
                Text(subtitle)
                    .font(AppFontV3.caption())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: Layout.tileMinHeight, alignment: .topLeading)
            .tileSurface()
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(subtitle)")
        }
        .buttonStyle(PressableStyle())
        .onAppear { animate = true }
    }
} 