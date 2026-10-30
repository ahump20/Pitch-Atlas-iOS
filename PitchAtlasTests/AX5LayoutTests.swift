import SwiftUI
import XCTest
@testable import PitchAtlas

/// The largest accessibility text size (AX5) on a 393pt phone: nothing a
/// reader scrolls past may ask for more width than the screen gives it, or the
/// whole column runs off the right edge.
@MainActor
final class AX5LayoutTests: XCTestCase {
    private let store = PitchStore()
    /// iPhone 17 Pro width less the Index's 16pt gutters.
    private let column: CGFloat = 393 - 32

    private func width<V: View>(_ view: V) -> CGFloat {
        let host = UIHostingController(rootView: view
            .environment(store)
            .environment(\.dynamicTypeSize, .accessibility5))
        return host.sizeThatFits(in: CGSize(width: column, height: 20_000)).width
    }

    func testEveryIndexRowFitsTheColumnAtAX5() {
        for entry in store.repertoire.entries {
            XCTAssertLessThanOrEqual(width(IndexRow(entry: entry)), column + 0.5, entry.name)
        }
    }
}
