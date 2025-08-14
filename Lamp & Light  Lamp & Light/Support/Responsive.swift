import SwiftUI

struct ResponsiveGrid: SwiftUI.Layout {
	func sizeThatFits(proposal: ProposedViewSize, subviews: SwiftUI.LayoutSubviews, cache: inout ()) -> CGSize {
		let width = proposal.width ?? 0
		let columns = Self.columns(for: width)
		let tileW = width / CGFloat(columns) - Theme.Spacing.lg
		var x: CGFloat = 0, y: CGFloat = 0, rowMaxH: CGFloat = 0
		var i = 0
		for v in subviews {
			let size = v.sizeThatFits(.init(width: tileW, height: nil))
			rowMaxH = max(rowMaxH, size.height)
			if i % columns == columns - 1 {
				y += rowMaxH + Theme.Spacing.lg
				x = 0
				rowMaxH = 0
			} else {
				x += tileW + Theme.Spacing.lg
			}
			i += 1
		}
		if i % columns != 0 { y += rowMaxH + Theme.Spacing.lg }
		return .init(width: width, height: y)
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: SwiftUI.LayoutSubviews, cache: inout ()) {
		let columns = Self.columns(for: bounds.width)
		let tileW = bounds.width / CGFloat(columns) - Theme.Spacing.lg
		var x = bounds.minX, y = bounds.minY, rowMaxH: CGFloat = 0
		var i = 0
		for v in subviews {
			let size = v.sizeThatFits(.init(width: tileW, height: nil))
			v.place(at: .init(x: x, y: y), anchor: .topLeading, proposal: .init(width: tileW, height: size.height))
			rowMaxH = max(rowMaxH, size.height)
			if i % columns == columns - 1 {
				y += rowMaxH + Theme.Spacing.lg
				x = bounds.minX
				rowMaxH = 0
			} else {
				x += tileW + Theme.Spacing.lg
			}
			i += 1
		}
	}

	private static func columns(for width: CGFloat) -> Int {
		switch width {
		case ..<360: return 1
		case ..<600: return 2
		case ..<900: return 3
		default: return 4
		}
	}
}

/// Fits children without scroll by collapsing, truncating, or scaling.
/// Order matters. Put the most important blocks first.
struct ViewThatFitsOneScreen<Content: View>: View {
	let content: Content
	init(@ViewBuilder content: () -> Content) { self.content = content() }

	var body: some View {
		GeometryReader { geo in
			VStack(spacing: Theme.Spacing.lg) {
				content
			}
			.padding(Theme.Spacing.lg)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Theme.background.ignoresSafeArea())
			.modifier(FitToHeight(maxHeight: geo.size.height))
		}
	}
}

private struct FitToHeight: ViewModifier {
	var maxHeight: CGFloat
	func body(content: Content) -> some View {
		content
			.fixedSize(horizontal: false, vertical: true)
			.minimumScaleFactor(0.85)
			.lineLimit(4)
			.allowsTightening(true)
	}
} 