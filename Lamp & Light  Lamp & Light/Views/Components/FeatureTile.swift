import SwiftUI

struct FeatureTile: View {
	let title: String
	let subtitle: String
	let symbol: String
	let tint: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			ZStack {
				Circle().fill(tint.opacity(0.12)).frame(width: 36, height: 36)
				Image(systemName: symbol).foregroundStyle(tint).imageScale(.medium)
			}
			Text(title).font(AppFontV3.h2())
			Text(subtitle).font(AppFontV3.caption()).foregroundStyle(.secondary).lineLimit(1)
		}
		.tileSurface()
	}
} 