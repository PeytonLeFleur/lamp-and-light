import SwiftUI

struct AppBackground<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColor.mist, AppColor.softGreen.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            content.padding(.horizontal, 16)
        }
    }
} 