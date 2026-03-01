import SwiftUI

// MARK: - ThemeButton

struct ThemeButton: View {
    let iconName: String
    let title: String
    let subtitle: String
    var gradientColors: [Color] = AppColors.blueGradient
    var height: CGFloat = 70
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 48, height: 48)
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.90))
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            LinearGradient.appTheme(gradientColors)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .shadow(
            color: gradientColors[0].opacity(0.30),
            radius: 8,
            x: 0,
            y: 4
        )
        .contentShape(Rectangle())
    }
}
