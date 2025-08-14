import SwiftUI

struct Badge: View {
	var text: String
	var color: Color = S.mint

	var body: some View {
		Text(text)
			.font(AppFontV3.caption().weight(.semibold))
			.padding(.vertical, 6).padding(.horizontal, 10)
			.background(color.opacity(0.12), in: Capsule())
			.overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 0.6))
			.foregroundStyle(color.opacity(0.95))
			.accessibilityLabel(Text(text))
	}
} 