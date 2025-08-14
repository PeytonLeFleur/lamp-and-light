import SwiftUI

struct CanonicalTodayView: View {
    @Environment(\.dynamicTypeSize) private var dyn

    var body: some View {
        ViewThatFitsOneScreen {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                HStack {
                    Text("Lamp & Light")
                        .font(Theme.Type.title(dyn.sizeCategory))
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .imageScale(.large)
                        .foregroundStyle(Theme.accent)
                }

                // Daily passage
                SectionCard("Today’s Passage") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Proverbs 11:4")
                            .font(.headline)
                        Text("Wealth is worthless in the day of wrath, but righteousness delivers from death.")
                            .font(Theme.Type.body)
                            .lineLimit(3)
                            .minimumScaleFactor(0.9)
                    }
                }
                .frame(maxHeight: Theme.Caps.maxCardHeight)

                // Tiles
                ResponsiveGrid {
                    Tile(icon: "book.closed.fill", title: "Study", caption: "Short commentary and context") {}
                    Tile(icon: "hands.sparkles.fill", title: "Prayer", caption: "Four sentences to pray") {}
                    Tile(icon: "flag.checkered", title: "Challenge", caption: "A small act today") {}
                    Tile(icon: "calendar", title: "Plan", caption: "Set a reminder for tomorrow") {}
                }

                // Primary action
                PrimaryButton(title: "Start") { }
            }
        }
    }
}

#Preview { CanonicalTodayView() } 