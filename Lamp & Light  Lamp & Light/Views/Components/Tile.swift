import SwiftUI

struct Tile: View {
	let icon: String
	let title: String
	let caption: String
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
				Image(systemName: icon)
					.imageScale(.large)
					.padding(Theme.Spacing.sm)
					.background(Theme.accent.opacity(0.12))
					.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))

				Text(title)
					.font(.headline)
					.foregroundStyle(Theme.text)
					.lineLimit(1)
					.minimumScaleFactor(0.85)

				Text(caption)
					.font(.subheadline)
					.foregroundStyle(Theme.subtext)
					.lineLimit(2)
					.minimumScaleFactor(0.85)
			}
			.padding(Theme.Spacing.lg)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(Theme.card)
			.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
		}
		.buttonStyle(.plain)
	}
} 