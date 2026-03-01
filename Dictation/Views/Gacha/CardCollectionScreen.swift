import SwiftUI

// MARK: - CardCollectionScreen

struct CardCollectionScreen: View {
    @EnvironmentObject var ownedStore: OwnedCardsStore
    @EnvironmentObject private var cardZoomStore: CardZoomStore

    @State private var selectedTab: String = "全て"

    private let allCards = GachaCardLoader.shared.allCards
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let cardAspect: CGFloat = AppConfig.cardAspectRatio
    private let tabs = ["全て", "共通", "初級", "中級", "上級"]

    private var filteredCards: [GachaCard] {
        let owned = allCards.filter { ownedStore.owns($0.id) }
        if selectedTab == "全て" { return owned }
        return owned.filter { $0.grade == selectedTab }
    }

    private var ownedCount: Int { allCards.filter { ownedStore.owns($0.id) }.count }
    private var totalCount: Int { allCards.count }

    var body: some View {
        VStack(spacing: 0) {
            // 級タブ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs, id: \.self) { tab in
                        let isSelected = tab == selectedTab
                        let count = tab == "全て"
                            ? allCards.filter { ownedStore.owns($0.id) }.count
                            : allCards.filter { ownedStore.owns($0.id) && $0.grade == tab }.count
                        Button {
                            selectedTab = tab
                        } label: {
                            Text("\(tab) \(count)")
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(isSelected ? AppColors.primary : AppColors.primary.opacity(0.10))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // カード一覧
            ScrollView {
                VStack(spacing: 20) {
                    if filteredCards.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.primary.opacity(0.4))
                            Text("テストをクリアしてカードをゲットしよう")
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredCards) { card in
                                cardCell(card: card)
                                    .onTapGesture { cardZoomStore.show(card) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background)
        .navigationTitle("\(ownedCount) / \(totalCount) 枚所有")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func cardCell(card: GachaCard) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w / cardAspect

            CardImageView(filename: card.filename)
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .aspectRatio(cardAspect, contentMode: .fit)
    }
}
