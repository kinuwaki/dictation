import SwiftUI

// MARK: - SparkleParticle

struct SparkleParticle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let duration: Double
    let birthTime: TimeInterval
    let phase: Double
    let color: Color

    init(isLight: Bool = false) {
        x = CGFloat.random(in: 0...1)
        y = CGFloat.random(in: 0.2...1.0)
        size = CGFloat.random(in: 8...20)
        opacity = Double.random(in: 0.5...1.0)
        duration = Double.random(in: 4.0...9.0)
        birthTime = Date.timeIntervalSinceReferenceDate - Double.random(in: 0...9)
        phase = Double.random(in: 0...(2 * .pi))
        let palette = isLight ? AppColors.sparkleLightPalette : AppColors.sparkleDarkPalette
        color = palette.randomElement() ?? .white
    }
}
