import SwiftUI

struct PressableStyle: ButtonStyle {
	var scale: CGFloat = 0.97
	var opacity: Double = 0.98

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? scale : 1)
			.opacity(configuration.isPressed ? opacity : 1)
			.animation(.spring(response: 0.22, dampingFraction: 0.88), value: configuration.isPressed)
	}
} 