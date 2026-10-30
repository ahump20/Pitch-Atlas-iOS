import SwiftUI
import UIKit

// The value types the generated WebTokens.swift is written in. Hand-written so
// the generated file stays pure data.

struct WebColor: Hashable {
    let rgb: UInt32
    let alpha: Double
}

struct WebStop: Hashable {
    let color: WebColor
    let location: Double
}

/// A CSS `linear-gradient(<angle>deg, …)` — angle in CSS degrees (0 = to top,
/// 90 = to right), stops 0…1 in source order.
struct WebGradient: Hashable {
    let angle: Double
    let stops: [WebStop]
}

struct WebAccent: Hashable {
    let c1: UInt32
    let c2: UInt32
    let c3: UInt32
    let finish: String?
}

struct WebCardFinish: Hashable {
    let foil: WebGradient
    let ring: WebColor
    let ringIn: WebColor
}

extension Color {
    init(web: WebColor) {
        self.init(.sRGB,
                  red: Double((web.rgb >> 16) & 0xFF) / 255,
                  green: Double((web.rgb >> 8) & 0xFF) / 255,
                  blue: Double(web.rgb & 0xFF) / 255,
                  opacity: web.alpha)
    }
    init(rgb: UInt32) { self.init(web: WebColor(rgb: rgb, alpha: 1)) }
}

extension UIColor {
    convenience init(web: WebColor) {
        self.init(red: CGFloat((web.rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((web.rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(web.rgb & 0xFF) / 255,
                  alpha: web.alpha)
    }
}
