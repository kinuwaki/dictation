import SwiftUI

// MARK: - GradientButton

struct GradientButton: View {
    let title: String
    var gradientColors: [Color] = AppColors.nextButtonGradient
    var height: CGFloat = 56
    var fontSize: CGFloat = 18
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    private var activeColors: [Color] {
        isDisabled
            ? [AppColors.disabledBackground, AppColors.disabledBackground]
            : gradientColors
    }

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            action()
        }) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(isDisabled ? AppColors.disabledText : .white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    LinearGradient.appTheme(activeColors)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                .shadow(
                    color: isDisabled ? .clear : gradientColors[0].opacity(0.30),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(isPressed ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.10), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .disabled(isDisabled)
    }
}
