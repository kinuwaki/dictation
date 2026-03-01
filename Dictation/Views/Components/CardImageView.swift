import SwiftUI

// MARK: - CardImageView

struct CardImageView: View {
    let filename: String

    var body: some View {
        if let uiImage = Self.loadImage(filename: filename) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color(UIColor.systemGray3))
        }
    }

    static func loadImage(filename: String) -> UIImage? {
        let dir = (Bundle.main.bundlePath as NSString).appendingPathComponent("Assets/Cards")
        let path = (dir as NSString).appendingPathComponent(filename)
        if let image = UIImage(contentsOfFile: path) {
            return image
        }

        // フォールバック: forResource で検索
        let ns = (filename as NSString)
        let name = ns.deletingPathExtension
        let ext  = ns.pathExtension
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Assets/Cards"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        AppLogger.warning("[CardImage] NOT FOUND in bundle: \(filename)")
        return nil
    }
}
