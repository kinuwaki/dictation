import SwiftUI

// MARK: - Tab definition

enum AppTab: Int, CaseIterable {
    case practice, review, exam

    var title: String {
        switch self {
        case .practice: return "ディクテーション"
        case .review:   return "復習"
        case .exam:     return "テスト"
        }
    }

    var icon: String {
        switch self {
        case .practice: return "headphones"
        case .review:   return "arrow.clockwise"
        case .exam:     return "doc.text.fill"
        }
    }
}

// MARK: - Navigation destination types

struct LevelDestination: Hashable {
    let level: Level
}

struct DictationDestination: Hashable {
    let mode: DictationMode

    func hash(into hasher: inout Hasher) {
        switch mode {
        case .practice(let level, let setIndex):
            hasher.combine(0)
            hasher.combine(level)
            hasher.combine(setIndex)
        case .review:
            hasher.combine(1)
        case .exam(let level):
            hasher.combine(2)
            hasher.combine(level)
        case .daily(let itemId):
            hasher.combine(3)
            hasher.combine(itemId)
        }
    }

    static func == (lhs: DictationDestination, rhs: DictationDestination) -> Bool {
        switch (lhs.mode, rhs.mode) {
        case (.practice(let l1, let s1), .practice(let l2, let s2)):
            return l1 == l2 && s1 == s2
        case (.review, .review):
            return true
        case (.exam(let l1), .exam(let l2)):
            return l1 == l2
        case (.daily(let q1), .daily(let q2)):
            return q1 == q2
        default:
            return false
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let allItems: [DictationItem]

    @EnvironmentObject var progressStore: UserProgressStore
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .practice
    @State private var showSettings = false
    @State private var showDailyPractice = false
    @State private var dailyItemId: String? = nil

    @State private var practicePath = NavigationPath()
    @State private var reviewPath   = NavigationPath()
    @State private var examPath     = NavigationPath()

    @State private var resetTokens: [AppTab: UUID] = Dictionary(
        uniqueKeysWithValues: AppTab.allCases.map { ($0, UUID()) }
    )

    // MARK: - Tab switching logic

    private func onTabTapped(_ tab: AppTab) {
        withTransaction(Transaction(animation: nil)) {
            if tab == selectedTab {
                resetTab(tab)
            } else {
                resetTab(selectedTab)
                selectedTab = tab
            }
        }
    }

    private func resetTab(_ tab: AppTab) {
        switch tab {
        case .practice: practicePath = NavigationPath()
        case .review:   reviewPath   = NavigationPath()
        case .exam:     examPath     = NavigationPath()
        }
        resetTokens[tab] = UUID()
    }

    private var currentTabPath: NavigationPath {
        switch selectedTab {
        case .practice: return practicePath
        case .review:   return reviewPath
        case .exam:     return examPath
        }
    }

    var body: some View {
        ZStack {
            if selectedTab == .practice {
                NavigationStack(path: $practicePath) {
                    LevelListView(allItems: allItems)
                        .navigationDestination(for: LevelDestination.self) { dest in
                            SetIndexView(
                                level: dest.level,
                                allItems: allItems
                            )
                        }
                        .navigationDestination(for: DictationDestination.self) { dest in
                            DictationView(mode: dest.mode, allItems: allItems)
                        }
                }
                .id(resetTokens[.practice])
            } else if selectedTab == .review {
                NavigationStack(path: $reviewPath) {
                    ReviewListView(allItems: allItems)
                        .navigationDestination(for: DictationDestination.self) { dest in
                            DictationView(mode: dest.mode, allItems: allItems)
                        }
                }
                .id(resetTokens[.review])
            } else {
                NavigationStack(path: $examPath) {
                    ExamSetupView(allItems: allItems)
                        .navigationDestination(for: DictationDestination.self) { dest in
                            DictationView(mode: dest.mode, allItems: allItems)
                        }
                }
                .id(resetTokens[.exam])
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab, onTabSelected: onTabTapped)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(progressStore)
                .environmentObject(iapManager)
        }
        .fullScreenCover(isPresented: $showDailyPractice) {
            if let itemId = dailyItemId {
                NavigationStack {
                    DictationView(mode: .daily(itemId: itemId), allItems: allItems)
                }
            }
        }
        .onChange(of: appState.pendingItemId) { _, itemId in
            guard let itemId else { return }
            dailyItemId = itemId
            appState.pendingItemId = nil
            showDailyPractice = true
        }
        .overlay(alignment: .topTrailing) {
            if currentTabPath.isEmpty {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.primary)
                        .padding(14)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                        )
                }
                .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 60 : 8)
                .padding(.trailing, 16)
                .fixedSize()
            }
        }
    }
}

// MARK: - CustomTabBar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    var onTabSelected: (AppTab) -> Void = { _ in }
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItemView(
                    tab: tab,
                    selectedTab: $selectedTab,
                    namespace: tabNamespace,
                    onTap: { onTabSelected(tab) }
                )
            }
        }
        .frame(height: 82)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - TabBarItemView

private struct TabBarItemView: View {
    let tab: AppTab
    @Binding var selectedTab: AppTab
    let namespace: Namespace.ID
    var onTap: () -> Void = {}

    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            selectedTab = tab
            onTap()
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient.appTab)
                        .matchedGeometryEffect(id: "tabHighlight", in: namespace)
                        .frame(width: 80, height: 60)
                }

                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 22))
                    Text(tab.title)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(isSelected ? Color.white : AppColors.textSecondary)
                .frame(width: 80, height: 60)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
