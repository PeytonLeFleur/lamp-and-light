import SwiftUI

struct TopGreeting: View {
	let name: String
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Good morning, \(name)")
				.font(AppFontV3.h1())
		}
	}
} 