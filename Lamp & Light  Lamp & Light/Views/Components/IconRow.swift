import SwiftUI

struct IconRow: View {
	let icon: String
	let title: String
	let subtitle: String?

	init(icon: String, title: String, subtitle: String? = nil) {
		self.icon = icon; self.title = title; self.subtitle = subtitle
	}
	var body: some View {
		HStack(spacing: S.m) {
			Image(systemName: icon).imageScale(.large)
				.frame(width: 32, height: 32).foregroundStyle(.secondary)
			VStack(alignment: .leading, spacing: 2) {
				Text(title).font(AppFontV3.body())
				if let s = subtitle { Text(s).font(AppFontV3.caption()).foregroundStyle(.secondary) }
			}
			Spacer()
		}
		.padding(.vertical, 2)
	}
} 