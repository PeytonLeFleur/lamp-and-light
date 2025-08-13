import SwiftUI

struct ShareCardView: View {
    let name: String
    let days: Int
    let verse: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Lamp & Light")
                .font(AppFont.headline())
                .foregroundColor(AppColor.ink)
            
            Text("\(days)-day streak")
                .font(AppFont.title())
                .foregroundColor(AppColor.primaryGreen)
            
            Text(verse)
                .font(AppFont.body())
                .foregroundColor(AppColor.slate)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(24)
        .shadow(radius: 12)
    }
}

#Preview {
    ShareCardView(name: "John", days: 7, verse: "God is our refuge and strength, a very present help in trouble.")
        .padding()
        .background(AppColor.mist)
} 