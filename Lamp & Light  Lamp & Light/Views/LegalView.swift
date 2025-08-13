import SwiftUI

struct LegalView: View {
    enum Kind: String, CaseIterable { case terms = "Terms", privacy = "Privacy", disclaimer = "Disclaimer" }
    @State private var kind: Kind = .terms

    var body: some View {
        AppBackground {
            VStack(spacing: 12) {
                Picker("Section", selection: $kind) {
                    ForEach(Kind.allCases, id: \.self) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .pickerStyle(.segmented)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(kind.rawValue)
                            .font(AppFont.title())
                        Text(loadMarkdown(kind))
                            .font(AppFont.body())
                            .foregroundColor(AppColor.slate)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 6)
                    }
                    .card()
                }
            }
        }
        .navigationTitle("About & Legal")
    }

    private func loadMarkdown(_ kind: Kind) -> String {
        let name: String
        switch kind {
        case .terms: name = "terms"
        case .privacy: name = "privacy"
        case .disclaimer: name = "disclaimer"
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "md", subdirectory: "legal"),
           let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return ""
    }
} 