import SwiftUI

struct ScrollProgressPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 0

    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = BlazeCompanionController.clampProgress(nextValue())
    }
}
