import Foundation
import Combine

// MARK: - AppState

final class AppState: ObservableObject {
    static let shared = AppState()
    private init() {}

    /// 通知タップで受け取った item ID。nil = 通常起動
    @Published var pendingItemId: String? = nil
}
