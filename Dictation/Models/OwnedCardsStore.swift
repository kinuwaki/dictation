import Foundation
import Combine

// MARK: - OwnedCardsStore

final class OwnedCardsStore: ObservableObject {
    static let shared = OwnedCardsStore()
    private let key = AppConfig.Keys.ownedCardIDs

    @Published private(set) var ownedIDs: Set<String> = []

    private init() { load() }

    func load() {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        ownedIDs = Set(arr)
    }

    func save() {
        UserDefaults.standard.set(Array(ownedIDs), forKey: key)
    }

    func add(id: String) {
        ownedIDs.insert(id)
        save()
    }

    func addAll(ids: [String]) {
        ids.forEach { ownedIDs.insert($0) }
        save()
    }

    func owns(_ id: String) -> Bool {
        ownedIDs.contains(id)
    }

    func debugClearAll() {
        ownedIDs = []
        save()
    }

    func drawAndAdd(from all: [GachaCard], count: Int) -> [GachaCard] {
        var result: [GachaCard] = []
        var tempOwned = ownedIDs

        for _ in 0..<count {
            let unowned = all.filter { !tempOwned.contains($0.id) }
            let pool = unowned.isEmpty ? all : unowned
            if let card = pool.randomElement() {
                result.append(card)
                tempOwned.insert(card.id)
            }
        }

        addAll(ids: result.map(\.id))
        return result
    }
}
