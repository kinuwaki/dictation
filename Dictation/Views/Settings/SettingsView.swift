import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var progressStore: UserProgressStore
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppConfig.Keys.settingsNotification) private var notificationEnabled = true
    @AppStorage(AppConfig.Keys.settingsSound)        private var soundEnabled = true

    @State private var showDebugMenu     = false
    @State private var showShareSheet    = false

    var body: some View {
        NavigationStack {
            List {
                settingToggleRow(
                    icon: "bell.fill", iconColor: AppColors.settingsBell,
                    title: "通知", subtitle: "リマインダーを受け取る",
                    isOn: $notificationEnabled
                )
                .onChange(of: notificationEnabled) { _, enabled in
                    Task {
                        if enabled {
                            await NotificationManager.requestAuthorization()
                            if let item = DictationDataLoader.shared.load().randomElement() {
                                await NotificationManager.scheduleDailyPractice(item: item)
                            }
                        } else {
                            NotificationManager.cancelDailyPractice()
                        }
                    }
                }

                settingToggleRow(
                    icon: "speaker.wave.2.fill", iconColor: AppColors.settingsSound,
                    title: "効果音", subtitle: "音楽・効果音のON/OFF",
                    isOn: $soundEnabled
                )

                settingActionRow(
                    icon: "arrow.clockwise", iconColor: AppColors.settingsSound,
                    title: "購入の復元", subtitle: "過去の購入を復元する"
                ) {
                    Task { await iapManager.restorePurchases() }
                } trailing: {
                    AnyView(
                        Text("復元")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppColors.primary.opacity(0.12))
                            .clipShape(Capsule())
                    )
                }

                settingActionRow(
                    icon: "star.fill", iconColor: AppColors.settingsStar,
                    title: "アプリをレビューする", subtitle: "App Storeでレビューを書く"
                ) {
                    if let url = URL(string: AppConfig.reviewURL) {
                        UIApplication.shared.open(url)
                    }
                } trailing: { AnyView(chevron) }

                settingActionRow(
                    icon: "square.and.arrow.up", iconColor: AppColors.settingsShare,
                    title: "このアプリを友達に教える", subtitle: "アプリをシェアする"
                ) {
                    showShareSheet = true
                } trailing: { AnyView(chevron) }

                settingActionRow(
                    icon: "info.circle.fill", iconColor: AppColors.settingsInfo,
                    title: "アプリについて", subtitle: "利用規約・お問い合わせなどはこちら"
                ) {
                    if let url = URL(string: AppConfig.aboutURL) {
                        UIApplication.shared.open(url)
                    }
                } trailing: {
                    AnyView(
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(AppColors.primary)
                    )
                }

                settingActionRow(
                    icon: "list.bullet.rectangle.fill", iconColor: AppColors.settingsBell,
                    title: AppConfig.dataNoticeTitle, subtitle: AppConfig.dataNoticeSubtitle
                ) {
                } trailing: { AnyView(chevron) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("設定")
                        .font(.system(size: 17, weight: .semibold))
                        .gesture(
                            LongPressGesture(minimumDuration: 5)
                                .onEnded { _ in showDebugMenu = true }
                        )
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                NavigationStack {
                    DebugMenuView()
                        .environmentObject(progressStore)
                        .environmentObject(iapManager)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: AppConfig.shareURL) {
                    ShareSheet(items: [
                        "英語ディクテーション練習アプリです！",
                        url
                    ] as [Any])
                }
            }
        }
    }

    // MARK: - Row builders

    private func settingToggleRow(
        icon: String, iconColor: Color,
        title: String, subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            iconContainer(icon: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .medium))
                Text(subtitle).font(.system(size: 13)).foregroundStyle(AppColors.primary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func settingActionRow(
        icon: String, iconColor: Color,
        title: String, subtitle: String,
        action: @escaping () -> Void,
        @ViewBuilder trailing: () -> AnyView
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconContainer(icon: icon, color: iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.primary)
                }
                Spacer()
                trailing()
            }
            .padding(.vertical, 4)
        }
    }

    private func iconContainer(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.primary)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
