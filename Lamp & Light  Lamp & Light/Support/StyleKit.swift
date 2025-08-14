import SwiftUI

enum S {
	// Spacing
	static let xs: CGFloat = 6
	static let s: CGFloat  = 10
	static let m: CGFloat  = 14
	static let l: CGFloat  = 18
	static let xl: CGFloat = 24
	static let xxl: CGFloat = 32

	// Corners
	static let rSm: CGFloat = 14
	static let rMd: CGFloat = 20
	static let rLg: CGFloat = 28

	// Colors pulled from current palette
	static let mint = Color(.systemGreen)
	static let mintSoft = Color(red: 0.84, green: 0.97, blue: 0.90) // subtle
	static let glassStroke = Color.white.opacity(0.55)
	static let shadow = Color.black.opacity(0.10)
}

enum AppFontV3 {
	static func title() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
	static func h1() -> Font { .system(.title, design: .rounded).weight(.bold) }
	static func h2() -> Font { .system(.title3, design: .rounded).weight(.semibold) }
	static func body() -> Font { .system(.body, design: .rounded) }
	static func caption() -> Font { .system(.footnote, design: .rounded) }
}

extension View {
	// Soft glass like the mock
	func surface() -> some View {
		self
			.padding(S.l)
			.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: S.rMd, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: S.rMd, style: .continuous)
					.strokeBorder(S.glassStroke, lineWidth: 0.6)
			)
			.shadow(color: S.shadow, radius: 12, x: 0, y: 8)
	}

	// For smaller tiles
	func tileSurface() -> some View {
		self
			.padding(S.m)
			.background(.thinMaterial, in: RoundedRectangle(cornerRadius: S.rSm, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: S.rSm, style: .continuous)
					.strokeBorder(Color.white.opacity(0.45), lineWidth: 0.6)
			)
	}

	// Backward compatible with any .card()
}

enum Layout {
	// Adaptive tile sizing
	static let tileMin: CGFloat = 116   // fits three across on small phones
	static let tileMax: CGFloat = 180
	static let tileMinHeight: CGFloat = 112
} 