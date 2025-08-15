import SwiftUI

struct BubblesBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [L2.green.opacity(0.08), .white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Circle()
                .fill(L2.blush.opacity(0.6))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(x: 140, y: -220)
                .accessibilityHidden(true)
            Circle()
                .fill(L2.sky.opacity(0.65))
                .frame(width: 420, height: 420)
                .blur(radius: 40)
                .offset(x: -160, y: 260)
                .accessibilityHidden(true)
        }
    }
} 