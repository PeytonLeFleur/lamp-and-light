import SwiftUI

struct LoadingCard: View {
    var text: String = "Loading…"
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(text).font(AppFont.body())
        }.card()
    }
}

struct ErrorCard: View {
    let text: String
    var retry: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text).font(AppFont.body())
            if let retry { PillButton(title: "Try Again", style: .secondary, systemImage: "arrow.clockwise", action: retry) }
        }.card()
    }
} 