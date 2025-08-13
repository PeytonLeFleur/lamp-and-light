import SwiftUI

struct LegalView: View {
    enum Kind { case terms, privacy }
    let kind: Kind

    private var filename: String { kind == .terms ? "terms" : "privacy" }

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(AppFont.title())
                    Text(loadMarkdown())
                        .font(AppFont.body())
                        .foregroundColor(AppColor.slate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                }
                .card()
            }
        }
        .navigationTitle(title)
    }

    private var title: String { kind == .terms ? "Terms of Use" : "Privacy Policy" }

    private func loadMarkdown() -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "md"),
              let data = try? Data(contentsOf: url),
              let str = String(data: data, encoding: .utf8) else { return "" }
        return str
    }
} 