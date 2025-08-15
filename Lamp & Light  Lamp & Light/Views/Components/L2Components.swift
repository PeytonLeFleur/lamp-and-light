import SwiftUI

struct Chip: View {
    var text: String
    var color: Color = L2.green
    var body: some View {
        Text(text.uppercased())
            .font(L2.cap().weight(.semibold))
            .foregroundStyle(color.opacity(0.9))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
            .accessibilityLabel(Text(text))
    }
}

struct PrimaryPill: View {
    var title: String
    var systemImage: String = "sparkles"
    var action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: L2.s) {
                Image(systemName: systemImage).imageScale(.medium)
                Text(title).font(L2.h())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [L2.green, L2.teal], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .pressAction {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = true }
        } onRelease: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = false }
        }
        .accessibilityLabel(Text(title))
    }
}

// Small helper for press feedback
extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}

struct PressActions: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
} 