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
        let ring = app.buttons["ring1"]
        if !ring.isHittable { app.swipeUp() }
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
        if !ring.isHittable { app.swipeUp() }
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
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        period.buttons["7"].tap()
        app.terminate()
        // Keep fixtures explicit on relaunch without clearing persisted settings.
        app.launchArguments = ["--ui-testing", "--preserve-test-settings"]
        app.launch()
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        XCTAssertTrue(period.buttons["7"].isSelected)
    }
}
