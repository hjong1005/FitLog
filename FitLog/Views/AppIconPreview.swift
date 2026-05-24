import SwiftUI

struct AppIconPreview: View {
    var size: CGFloat = 300

    private var scale: CGFloat { size / 300 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.216, blue: 0.373),
                    Color(red: 1.0, green: 0.624, blue: 0.039)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6 * scale) {
                dumbbellShape

                Image(systemName: "scope")
                    .font(.system(size: 82 * scale, weight: .regular))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }

    private var dumbbellShape: some View {
        HStack(spacing: 4 * scale) {
            RoundedRectangle(cornerRadius: 6 * scale)
                .fill(Color.white)
                .frame(width: 16 * scale, height: 60 * scale)
            RoundedRectangle(cornerRadius: 5 * scale)
                .fill(Color.white.opacity(0.85))
                .frame(width: 12 * scale, height: 48 * scale)

            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(Color.white)
                .frame(width: 44 * scale, height: 10 * scale)

            RoundedRectangle(cornerRadius: 5 * scale)
                .fill(Color.white.opacity(0.85))
                .frame(width: 12 * scale, height: 48 * scale)
            RoundedRectangle(cornerRadius: 6 * scale)
                .fill(Color.white)
                .frame(width: 16 * scale, height: 60 * scale)
        }
    }
}

#Preview {
    AppIconPreview()
        .previewLayout(.sizeThatFits)
        .padding(40)
        .background(Color.black)
}
