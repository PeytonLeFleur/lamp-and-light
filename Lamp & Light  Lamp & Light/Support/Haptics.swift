import UIKit

enum Haptics {
	static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
	static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
} 