import SwiftUI

// MARK: - SetIndexView

struct SetIndexView: View {
    let level: Level
    let allItems: [DictationItem]

    @EnvironmentObject var progressStore: UserProgressStore
    @EnvironmentObject var iapManager: IAPManager
    @State private var showPaywall = false

    private var totalSets: Int {
        level.totalSetCount
    }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ballGrid
            .background(AppColors.background)
            .navigationTitle(level.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                IAPPaywallView()
                    .environmentObject(iapManager)
            }
    }

    // MARK: - Ball grid

    private var ballGrid: some View {
        let spacing:  CGFloat = isIPad ? 20 : 12
        let padding:  CGFloat = isIPad ? 32 : 16

        return GeometryReader { geo in
            let availableWidth = geo.size.width - padding * 2
            let columns = isIPad ? 8 : 5
            let ballSize = ((availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.down)

            let gridItems = Array(repeating: GridItem(.fixed(ballSize), spacing: spacing), count: columns)

            ScrollView {
                LazyVGrid(columns: gridItems, spacing: spacing) {
                    // 表示用セット番号 1〜totalSets をループ
                    ForEach(1...max(totalSets, 1), id: \.self) { displayIndex in
                        let realSet = level.realSetIndex(for: displayIndex)
                        // サブレベル内での表示位置でロック判定
                        let isLocked = displayIndex > AppConstants.freeSetLimit && !iapManager.isPurchased

                        if isLocked {
                            Button {
                                showPaywall = true
                            } label: {
                                SetBallView(
                                    setIndex: displayIndex,
                                    progress: .notPlayed,
                                    ballSize: ballSize,
                                    isLocked: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: DictationDestination(
                                mode: .practice(level: level.sourceLevel, setIndex: realSet)
                            )) {
                                SetBallView(
                                    setIndex: displayIndex,
                                    progress: progressStore.progress.progress(
                                        for: UserProgress.setKey(level: level.sourceLevel, setIndex: realSet)
                                    ),
                                    ballSize: ballSize,
                                    isLocked: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(padding)
            }
        }
    }
}

// MARK: - SetBallView

struct SetBallView: View {
    let setIndex: Int
    let progress: UserProgress.SetProgress
    var ballSize: CGFloat = 56
    var isLocked: Bool = false

    private var color: Color {
        if isLocked { return AppColors.ballNotPlayed.opacity(0.5) }
        switch progress {
        case .notPlayed: return AppColors.ballNotPlayed
        case .partial:   return AppColors.ballPartial
        case .good:      return AppColors.ballGood
        case .perfect:   return AppColors.ballPerfect
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: ballSize, height: ballSize)
                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: ballSize * 0.35, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text("\(setIndex)")
                    .font(.system(size: ballSize * 0.38, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
