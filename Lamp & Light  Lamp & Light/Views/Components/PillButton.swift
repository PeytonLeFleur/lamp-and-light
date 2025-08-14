import SwiftUI

struct PillButton: View {
	enum Style { case primary, secondary, danger, large }
	var title: String
	var style: Style = .primary
	var systemImage: String? = nil
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: S.s) {
				if let systemImage { Image(systemName: systemImage) }
				Text(title).font(style == .large ? AppFontV3.h1() : AppFontV3.h2())
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, style == .large ? 18 : 14)
		}
		.buttonStyle(.plain)
		.background(background)
		.foregroundStyle(foreground)
		.clipShape(Capsule())
		.shadow(color: Color.black.opacity(style == .secondary ? 0.08 : 0.18), radius: 18, x: 0, y: 10)
		.accessibilityLabel(Text(title))
	}

	@ViewBuilder private var background: some View {
		switch style {
		case .primary, .large:
			LinearGradient(colors: [S.mint, Color(.systemTeal)], startPoint: .leading, endPoint: .trailing)
		case .secondary:
			Color(.systemGray6)
		case .danger:
			LinearGradient(colors: [Color(.systemRed), Color(.systemPink)], startPoint: .leading, endPoint: .trailing)
		}
	}
	private var foreground: Color { style == .secondary ? .primary : .white }
} 