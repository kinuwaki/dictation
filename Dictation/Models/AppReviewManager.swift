import StoreKit
import UIKit

// MARK: - AppReviewManager

enum AppReviewManager {

    static let triggerCounts = [10, 30, 50, 75, 100, 150, 200, 250, 300]

    private enum Keys {
        static let launchCount         = AppConfig.Keys.launchCount
        static let requestedAtCount    = AppConfig.Keys.reviewRequestedAt
    }

    @discardableResult
    static func incrementAndCheck() -> Int {
        let count = UserDefaults.standard.integer(forKey: Keys.launchCount) + 1
        UserDefaults.standard.set(count, forKey: Keys.launchCount)

        let lastRequested = UserDefaults.standard.integer(forKey: Keys.requestedAtCount)
        guard triggerCounts.contains(count), count > lastRequested else { return count }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            requestReview(atCount: count)
        }
        return count
    }

    static func forceRequest() {
        Task { @MainActor in
            let count = UserDefaults.standard.integer(forKey: Keys.launchCount)
            requestReview(atCount: count)
        }
    }

    @MainActor
    private static func requestReview(atCount count: Int) {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        SKStoreReviewController.requestReview(in: scene)
        UserDefaults.standard.set(count, forKey: Keys.requestedAtCount)
    }
}
