import SwiftUI

// MARK: - CardZoomStore

final class CardZoomStore: ObservableObject {
    static let shared = CardZoomStore()
    private init() {}

    @Published var zoomCard: GachaCard? = nil

    func show(_ card: GachaCard) { zoomCard = card }
    func hide()                  { zoomCard = nil  }
}
