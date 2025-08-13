import SwiftUI
import CoreData

struct WhyThisPassageSheet: View {
    let reference: String
    let themes: [String]
    let reasons: [String]
    var body: some View {
        NavigationView {
            AppBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why this passage").font(AppFont.title())
                    Text(reference).font(AppFont.headline())
                    if reasons.isEmpty {
                        Text("Chosen for comfort and clarity this season.").font(AppFont.body())
                    } else {
                        ForEach(reasons, id: \.self) { r in
                            HStack { Image(systemName: "checkmark.circle.fill"); Text("You have been writing about \(r).") }
                                .font(AppFont.body())
                        }
                    }
                    Text("Themes: \(themes.joined(separator: ", "))").font(AppFont.caption()).foregroundColor(.secondary)
                    Spacer()
                }.card()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WhyThisPassageSheet(reference: "Psalm 46:1-3", themes: ["anxiety","refuge"], reasons: ["anxiety"]) 
} 