import SwiftUI
import UserNotifications

@main
struct DictationApp: App {
    @StateObject private var progressStore   = UserProgressStore.shared
    @StateObject private var ownedCardsStore = OwnedCardsStore.shared
    @StateObject private var iapManager      = IAPManager.shared
    @StateObject private var cardZoomStore   = CardZoomStore.shared
    @StateObject private var appState        = AppState.shared

    @Environment(\.scenePhase) private var scenePhase

    @State private var allItems: [DictationItem] = []

    private let notificationDelegate = NotificationTapDelegate()

    init() {
        AppReviewManager.incrementAndCheck()
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if allItems.isEmpty {
                    AppColors.background.ignoresSafeArea()
                } else {
                    MainTabView(allItems: allItems)
                }

                if let card = cardZoomStore.zoomCard {
                    CardZoomOverlay(card: card) {
                        cardZoomStore.hide()
                    }
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: cardZoomStore.zoomCard?.id)
            .environmentObject(progressStore)
            .environmentObject(ownedCardsStore)
            .environmentObject(iapManager)
            .environmentObject(cardZoomStore)
            .environmentObject(appState)
            .preferredColorScheme(.light)
            .task {
                let t0 = Date()
                AppLogger.debug("[起動] .task 開始")

                let t1 = Date()
                let items = await Task.detached(priority: .userInitiated) {
                    DictationDataLoader.shared.load()
                }.value
                AppLogger.debug("[起動] データ読み込み完了: \(String(format: "%.3f", Date().timeIntervalSince(t1)))s (\(items.count)問)")

                let t2 = Date()
                allItems = items
                AppLogger.debug("[起動] allItems セット完了: \(String(format: "%.3f", Date().timeIntervalSince(t2)))s")

                let t3 = Date()
                async let notificationSetup: Void = {
                    await NotificationManager.requestAuthorization()
                    if let item = items.randomElement() {
                        await NotificationManager.scheduleDailyPractice(item: item)
                    }
                }()
                async let productLoad: Void = iapManager.loadProducts()
                _ = await (notificationSetup, productLoad)
                AppLogger.debug("[起動] 通知+IAP並列完了: \(String(format: "%.3f", Date().timeIntervalSince(t3)))s")

                AppLogger.debug("[起動] .task 全体: \(String(format: "%.3f", Date().timeIntervalSince(t0)))s")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await iapManager.refreshNow() }
                }
            }
        }
    }
}

// MARK: - NotificationTapDelegate

final class NotificationTapDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let itemId = userInfo["itemId"] as? String {
            DispatchQueue.main.async {
                AppState.shared.pendingItemId = itemId
            }
        }
        completionHandler()
    }
}
