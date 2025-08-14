import SwiftUI

struct PrimaryButton: View {
	let title: String
	var action: () -> Void
	var body: some View {
		Button(title, action: action)
			.buttonStyle(.borderedProminent)
			.tint(Theme.accent)
			.controlSize(.large)
			.frame(maxWidth: .infinity)
			.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
	}
} 