import SwiftUI
import UIKit
import XCTest
@testable import PitchAtlas

final class BlazeCompanionTests: XCTestCase {

    func testReducedMotionReturnsStaticState() {
        XCTAssertEqual(
            BlazeCompanionController.effectiveMood(base: .chasing, enabled: true, reduceMotion: true),
            .still
        )
        XCTAssertEqual(
            BlazeCompanionController.effectiveMood(base: .concerned, enabled: true, reduceMotion: true),
            .concerned
        )
    }

    func testDisabledCompanionReturnsHiddenState() {
        XCTAssertEqual(
            BlazeCompanionController.effectiveMood(base: .sniffing, enabled: false, reduceMotion: false),
            .hidden
        )
        XCTAssertEqual(BlazeMotionSettings.appStorageKey, "blazeCompanionEnabled")
    }

    func testTabContextMapsToMood() {
        XCTAssertEqual(BlazeMood.mood(for: .atlas), .sniffing)
        XCTAssertEqual(BlazeMood.mood(for: .index), .hidden)
        XCTAssertEqual(BlazeMood.mood(for: .grips), .hidden)
        XCTAssertEqual(BlazeMood.mood(for: .craftsmen), .idle)
        XCTAssertEqual(BlazeMood.mood(for: .sources), .still)
    }

    func testSeriousFlowMapsToStill() {
        for tab in AppTab.allCases {
            XCTAssertEqual(BlazeMood.mood(for: tab, seriousFlow: true), .still)
        }
    }

    func testScrollProgressClampsBetweenZeroAndOne() {
        XCTAssertEqual(BlazeCompanionController.clampProgress(-2), 0)
        XCTAssertEqual(BlazeCompanionController.clampProgress(0.4), 0.4)
        XCTAssertEqual(BlazeCompanionController.clampProgress(2), 1)
        XCTAssertEqual(BlazeCompanionController.clampProgress(.infinity), 0)
    }

    func testRapidProgressChangesDoNotEscapeClamp() {
        let controller = BlazeCompanionController()
        for i in -100...100 {
            controller.update(progress: Double(i) / 10)
            XCTAssertGreaterThanOrEqual(controller.scrollProgress, 0)
            XCTAssertLessThanOrEqual(controller.scrollProgress, 1)
        }
    }

    func testBlazeImageAssetsAreBundled() {
        for mood in BlazeMood.allCases where mood != .hidden {
            XCTAssertNotNil(UIImage(named: mood.imageName), "\(mood.imageName) missing")
        }
    }

    func testCompanionClearsTabBarZone() {
        XCTAssertGreaterThanOrEqual(BlazeMotionSettings.tabBarClearance, 52)
    }

    func testDecorativeViewCanMountWithoutAccessibilityCrash() {
        let host = UIHostingController(rootView: BlazeCompanionView(selectedTab: .atlas))
        host.loadViewIfNeeded()
        XCTAssertNotNil(host.view)
    }
}
