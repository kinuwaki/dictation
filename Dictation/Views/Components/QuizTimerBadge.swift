import SwiftUI

// MARK: - QuizTimerBadge

struct QuizTimerBadge: View {
    let timerText: String
    let isWarning: Bool

    private var color: Color {
        isWarning ? AppColors.timerWarning : AppColors.timerNormal
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 13))
            Text(timerText)
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: isWarning)
    }
}
