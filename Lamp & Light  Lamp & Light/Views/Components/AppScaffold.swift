import SwiftUI

struct AppScaffold<Content: View>: View {
	let title: String
	var subtitle: String? = nil
	var showGreetingIcon: Bool = false
	let content: () -> Content
	var trailing: AnyView = AnyView(EmptyView())

	init(
		title: String,
		subtitle: String? = nil,
		showGreetingIcon: Bool = false,
		trailing: AnyView = AnyView(EmptyView()),
		@ViewBuilder content: @escaping () -> Content
	) {
		self.title = title
		self.subtitle = subtitle
		self.showGreetingIcon = showGreetingIcon
		self.trailing = trailing
		self.content = content
	}

	var body: some View {
		ZStack {
			LinearGradient(
				colors: [S.mint.opacity(0.18), Color(.systemBackground)],
				startPoint: .top, endPoint: .bottom
			)
			.ignoresSafeArea()

			ScrollView {
				VStack(alignment: .leading, spacing: S.xl) {
					HStack(alignment: .center) {
						VStack(alignment: .leading, spacing: 6) {
							Text(title).font(AppFontV3.title())
							if let subtitle {
								Text(subtitle).font(AppFontV3.caption()).foregroundStyle(.secondary)
							}
						}
						Spacer()
						if showGreetingIcon {
							Image(systemName: "lamp.table.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(S.mint, S.mint.opacity(0.5))
								.font(.system(size: 38))
						}
						trailing
					}

					content()
				}
				.padding(.horizontal, S.xl)
				.padding(.top, S.xl)
				.padding(.bottom, S.xxl)
			}
		}
	}
} 