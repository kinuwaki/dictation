import SwiftUI

// MARK: - CardGachaScreen

struct CardGachaScreen: View {
    let cardCount: Int
    let sourceLevel: String   // "level1", "level2", "level3"
    let onClose: () -> Void

    @State private var drawnCards: [GachaCard] = []
    @State private var currentIndex: Int = 0
    @State private var cardOpacity: Double = 0
    @State private var cardScale: Double = 0.8
    @State private var isLoading: Bool = true
    @State private var particles: [SparkleParticle] = []

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if !isLoading {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for p in particles {
                            let elapsed = now - p.birthTime
                            let progress = (elapsed / p.duration).truncatingRemainder(dividingBy: 1.0)
                            let x = p.x * size.width + sin(progress * .pi * 2 + p.phase) * 14
                            let y = p.y * size.height - progress * size.height * 0.30
                            let twinkle = (sin(progress * .pi * 4 + p.phase) + 1) / 2
                            let alpha = twinkle * (1 - progress) * p.opacity * 0.7

                            var symbol = context.resolve(
                                Text("\u{2726}").font(.system(size: p.size))
                            )
                            symbol.shading = .color(p.color.opacity(alpha))
                            context.draw(symbol, at: CGPoint(x: x, y: y))
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(AppConfig.gachaTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(AppConfig.gachaSubtitle)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.textSecondary)

                    if drawnCards.count > 1 {
                        Text("\(currentIndex + 1) / \(drawnCards.count) 枚目")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 52)
                .padding(.bottom, 24)

                Spacer()

                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppColors.primary)
                            .scaleEffect(1.6)
                    } else if currentIndex < drawnCards.count {
                        let card = drawnCards[currentIndex]
                        cardView(card: card)
                            .opacity(cardOpacity)
                            .scaleEffect(cardScale)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()

                if !isLoading {
                    actionButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            particles = (0..<35).map { _ in SparkleParticle(isLight: true) }
            let pool = GachaCardLoader.shared.cards(forLevel: sourceLevel)
            drawnCards = OwnedCardsStore.shared.drawAndAdd(from: pool, count: cardCount)
            showNextCard(animated: false)
        }
    }

    private func cardView(card: GachaCard) -> some View {
        GeometryReader { geo in
            let aspect: CGFloat = AppConfig.cardAspectRatio
            let maxW = geo.size.width * 0.90
            let maxH = geo.size.height * 0.95
            let byWidth  = maxW
            let byHeight = maxH * aspect
            let cardW = min(byWidth, byHeight)
            let cardH = cardW / aspect

            CardImageView(filename: card.filename)
                .frame(width: cardW, height: cardH)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.30), radius: 20, x: 0, y: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var actionButton: some View {
        let hasNext = currentIndex < drawnCards.count - 1
        let colors: [Color] = hasNext
            ? AppColors.gachaNextGradient
            : AppColors.gachaCloseGradient

        return GradientButton(
            title: hasNext ? "次のカード" : "閉じる",
            gradientColors: colors,
            height: 56
        ) {
            if hasNext {
                advanceCard()
            } else {
                onClose()
            }
        }
    }

    private func showNextCard(animated: Bool) {
        isLoading = true
        cardOpacity = 0
        cardScale = 0.8

        DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.3 : 0.1)) {
            isLoading = false
            SoundManager.shared.play(.gacha)
            withAnimation(.easeOut(duration: 0.6)) { cardScale = 1.0 }
            withAnimation(.easeIn(duration: 0.6))  { cardOpacity = 1.0 }
        }
    }

    private func advanceCard() {
        withAnimation(.easeIn(duration: 0.2)) { cardOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            showNextCard(animated: true)
        }
    }
}
