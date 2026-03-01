import SwiftUI

// MARK: - CardZoomOverlay

struct CardZoomOverlay: View {
    let card: GachaCard
    let onDismiss: () -> Void

    @State private var zoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.87)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }

                CardImageView(filename: card.filename)
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(zoom)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { zoom = min(max($0, 0.5), 4.0) }
                    )
                    .onTapGesture { onDismiss() }
            }
        }
    }
}
