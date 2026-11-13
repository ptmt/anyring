import XCTest

final class Tests_iOS: XCTestCase {
    @MainActor
    func testWidgetLinkOpensFirstRingAndUnknownRingDoesNotNavigate() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.open(URL(string: "anyprogress://ring/0")!)
        XCTAssertTrue(app.navigationBars["Ring 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["goal"].exists)
        // XCTest opens URLs via a new launch, so invalid links must stay at the overview.
        app.open(URL(string: "anyprogress://ring/999")!)
        XCTAssertTrue(app.navigationBars["AnyProgress"].waitForExistence(timeout: 5))
        app.open(URL(string: "anyprogress://rings")!)
        XCTAssertTrue(app.navigationBars["AnyProgress"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardAndMetricEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.navigationBars["AnyProgress"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["lastSync"].exists)
        capture(app, name: "Rounded dashboard")
        let ring = app.buttons["ring1"]
        for _ in 0..<6 {
            if ring.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(ring.waitForExistence(timeout: 5))
        ring.tap()
        XCTAssertTrue(app.navigationBars["Ring 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["goal"].exists)
        XCTAssertTrue(app.switches["Gradient"].exists)
    }

    @MainActor
    func testProviderSearchAndSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let ring = app.buttons["ring1"]
        for _ in 0..<6 {
            if ring.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(ring.waitForExistence(timeout: 5))
        ring.tap()
        app.buttons["HRV"].tap()
        XCTAssertTrue(app.navigationBars["Health Metrics"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Caffeine")
        let metric = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Caffeine'")).firstMatch
        XCTAssertTrue(metric.waitForExistence(timeout: 5))
        metric.tap()
        XCTAssertTrue(app.navigationBars["Ring 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Caffeine"].exists)
    }
    @MainActor
    func testTrackingPeriodPersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let period = app.segmentedControls["trackingPeriod"]
        for _ in 0..<6 {
            if period.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        period.buttons["7"].tap()
        app.terminate()
        // Keep fixtures explicit on relaunch without clearing persisted settings.
        app.launchArguments = ["--ui-testing", "--preserve-test-settings"]
        app.launch()
        for _ in 0..<6 {
            if period.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        XCTAssertTrue(period.buttons["7"].isSelected)
    }

    @MainActor
    func testShapeChoicePersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let picker = app.buttons["visualizationShape"]
        for _ in 0..<6 {
            if picker.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        XCTAssertTrue(app.navigationBars["Ring Shapes"].waitForExistence(timeout: 5))
        capture(app, name: "Shape gallery")
        let heart = app.buttons["shape.heart"]
        for _ in 0..<4 {
            if heart.isHittable { break }
            app.swipeUp()
        }
        capture(app, name: "Shape gallery continued")
        heart.tap()
        app.terminate()
        app.launchArguments = []
        app.launch()
        for _ in 0..<6 {
            if picker.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(picker.label.contains("Heart"))
    }

    @MainActor
    func testGradientAndGlowPalettesRenderOnTheDashboard() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let carousel = app.scrollViews["paletteCarousel"]
        for name in ["Neon", "Golden Hour"] {
            for _ in 0..<8 {
                if carousel.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(carousel.isHittable)
            let palette = app.buttons["palette.\(name)"]
            XCTAssertTrue(palette.exists)
            palette.tap()
            let header = app.descendants(matching: .any)["lastSync"]
            for _ in 0..<8 {
                if header.isHittable { break }
                app.swipeDown()
            }
            XCTAssertTrue(header.isHittable)
            capture(app, name: "\(name) ring rendering")
        }
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
