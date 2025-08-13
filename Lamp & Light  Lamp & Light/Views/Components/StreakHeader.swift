import SwiftUI

struct StreakHeader: View {
    let name: String
    let days: Int
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColor.sunshine).frame(width: 46, height: 46)
                Image(systemName: "flame.fill").foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, \(name)").font(AppFont.headline())
                Text("Streak \(days) days").font(AppFont.caption()).foregroundColor(.secondary)
            }
            Spacer()
            ProgressRing(progress: min(Double(days % 7)/7.0, 1))
        }
        .padding(.horizontal)
    }
} 