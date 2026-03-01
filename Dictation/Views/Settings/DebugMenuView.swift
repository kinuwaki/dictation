import SwiftUI
import UserNotifications

// MARK: - DebugMenuView

struct DebugMenuView: View {
    @EnvironmentObject var progressStore: UserProgressStore
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppConfig.Keys.debugNotificationTest) private var notificationTestEnabled = false
    @AppStorage(AppConfig.Keys.debugAutoClear)        private var autoClearEnabled = false

    private var launchCount: Int {
        UserDefaults.standard.integer(forKey: AppConfig.Keys.launchCount)
    }

    var body: some View {
        List {
            Section {
                Label("起動回数: \(launchCount)回", systemImage: "info.circle")
                    .foregroundStyle(.blue)
                Label("購入: \(iapManager.isPurchased ? "購入済み" : "未購入")",
                      systemImage: "cart")
                    .foregroundStyle(AppColors.debugOrange)
            }

            Section {
                Button {
                    UserDefaults.standard.set(0, forKey: AppConfig.Keys.launchCount)
                    UserDefaults.standard.set(0, forKey: AppConfig.Keys.reviewRequestedAt)
                } label: {
                    Label("起動回数リセット", systemImage: "arrow.clockwise")
                }

                Button(role: .destructive) {
                    OwnedCardsStore.shared.debugClearAll()
                } label: {
                    Label("保有カード全削除", systemImage: "trash.fill")
                }

                Button {
                    AppReviewManager.forceRequest()
                } label: {
                    Label("レビュー依頼強制表示", systemImage: "star")
                }

                Button {
                    Task {
                        if let item = DictationDataLoader.shared.load().randomElement() {
                            let center = UNUserNotificationCenter.current()
                            let content = UNMutableNotificationContent()
                            content.title = AppConfig.notificationTestTitle
                            content.body = String(item.answerText.prefix(40))
                            content.sound = .default
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                            let request = UNNotificationRequest(identifier: "debug_notification", content: content, trigger: trigger)
                            try? await center.add(request)
                        }
                    }
                } label: {
                    Label("通知テスト（5秒後）", systemImage: "bell.badge")
                }
            }

            Section {
                Toggle(isOn: $autoClearEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("テスト自動攻略")
                            .font(.system(size: 16))
                        Text("全テストで最終問題まで自動進行")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.leading, 4)
                }
                .tint(AppColors.debugToggleTint)
            }

            Section {
                Toggle(isOn: Binding(
                    get: { iapManager.isPurchased },
                    set: { iapManager.debugSetPurchased($0) }
                )) {
                    Label("購入状態切り替え", systemImage: "lock.open")
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .navigationTitle("デバッグメニュー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") { dismiss() }
                    .foregroundStyle(AppColors.primary)
            }
        }
    }
}
