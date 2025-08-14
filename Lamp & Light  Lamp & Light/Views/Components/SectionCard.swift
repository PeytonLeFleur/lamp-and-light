import SwiftUI

struct SectionCard<Content: View>: View {
	let title: String
	let content: Content
	init(_ title: String, @ViewBuilder content: () -> Content) {
		self.title = title; self.content = content()
	}

	@Environment(\.sizeCategory) var size

	var body: some View {
		VStack(alignment: .leading, spacing: Theme.Spacing.md) {
			Text(title)
				.font(Theme.Typography.heading(size))
				.foregroundStyle(Theme.text)
				.lineLimit(1)
				.minimumScaleFactor(0.8)

			content
		}
		.padding(Theme.Spacing.lg)
		.frame(maxWidth: .infinity)
		.background(Theme.card)
		.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
	}
} 