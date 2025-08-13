import SwiftUI

struct ProgressRing: View {
    var progress: Double   // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [AppColor.primaryGreen, AppColor.sunshine]), center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress*100))%").font(AppFont.headline())
        }
        .frame(width: 80, height: 80)
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
} 