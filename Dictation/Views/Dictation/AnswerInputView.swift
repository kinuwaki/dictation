import SwiftUI

// MARK: - AnswerInputView

/// テキスト入力 + 回答ボタン
struct AnswerInputView: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // テキストフィールド
            TextField("聞き取った英文を入力...", text: $text, axis: .vertical)
                .font(.system(size: 17))
                .lineLimit(3...6)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isFocused)
                .disabled(isDisabled)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSubmit()
                    }
                }

            // 回答ボタン
            GradientButton(
                title: "回答する",
                gradientColors: AppColors.nextButtonGradient,
                height: 52,
                isDisabled: text.trimmingCharacters(in: .whitespaces).isEmpty || isDisabled
            ) {
                isFocused = false
                onSubmit()
            }
        }
        .padding(16)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
