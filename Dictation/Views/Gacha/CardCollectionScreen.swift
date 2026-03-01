import SwiftUI

// MARK: - CardCollectionScreen

struct CardCollectionScreen: View {
    @EnvironmentObject var ownedStore: OwnedCardsStore
    @EnvironmentObject private var cardZoomStore: CardZoomStore

    private let allCards = GachaCardLoader.shared.allCards
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let cardAspect: CGFloat = AppConfig.cardAspectRatio

    private var ownedCards: [GachaCard] { allCards.filter { ownedStore.owns($0.id) } }
    private var ownedCount: Int { ownedCards.count }
    private var totalCount: Int { allCards.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if ownedCards.isEmpty {
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
                        ForEach(ownedCards) { card in
                            cardCell(card: card)
                                .onTapGesture { cardZoomStore.show(card) }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
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
