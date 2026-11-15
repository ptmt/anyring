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
        XCTAssertFalse(app.buttons["refresh"].exists)
        XCTAssertFalse(app.buttons["Refresh"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["lastSync"].exists)
        XCTAssertFalse(app.staticTexts["Not synced yet"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Last synced'")).firstMatch.exists)
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
        app.launchArguments = ["--ui-testing", "--preserve-test-settings"]
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
            let header = app.descendants(matching: .any)["metric.0"]
            for _ in 0..<8 {
                if header.isHittable { break }
                app.swipeDown()
            }
            XCTAssertTrue(header.isHittable)
            capture(app, name: "\(name) ring rendering")
        }
    }

    @MainActor
    func testPullToRefreshQueriesAndPersistsACompletedReading() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--refresh-probe", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let probe = app.descendants(matching: .any)["refreshVerification"]
        XCTAssertTrue(probe.waitForExistence(timeout: 10))
        func reading() -> [Double] {
            (probe.value as? String ?? "").split(separator: ",").compactMap { Double($0) }
        }
        let ready = NSPredicate { _, _ in
            let values = reading()
            return values.count == 2 && values[0] > 0 && values[1] > 0
        }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 10) == .completed)
        // Let launch/authorization work settle before measuring the gesture.
        let first = reading()
        sleep(2)
        let before = reading()
        XCTAssertEqual(first, before, "Automatic startup refresh must settle before the gesture")
        XCTAssertEqual(before.count, 2)
        guard before.count == 2 else { return }
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.1, thenDragTo: end)
        let refreshed = NSPredicate { _, _ in
            let after = reading()
            // Three dashboard queries plus three persisted widget-snapshot queries.
            return after.count == 2 && after[0] >= before[0] + 6 && after[1] > before[1]
        }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: refreshed, object: nil)], timeout: 10) == .completed,
                      "Pull must execute queries and replace the matching persisted reading")
        XCTAssertFalse(app.buttons["refresh"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["lastSync"].exists)
        capture(app, name: "Native pull refreshed dashboard")
    }

    @MainActor
    func testCustomNamePersistsClearsAndKeepsMetric() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.open(URL(string: "anyprogress://ring/0")!)
        let field = app.textFields["ringName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        guard field.exists else { return }
        field.tap()
        field.typeText("Morning recovery with a personal name")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["HRV"].exists)
        capture(app, name: "Custom name editor")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--preserve-test-settings"]
        app.launch()
        let metric = app.descendants(matching: .any)["metric.0"]
        XCTAssertTrue(metric.waitForExistence(timeout: 5))
        XCTAssertTrue(metric.label.contains("Morning recovery with a personal name"))
        capture(app, name: "Custom name dashboard after relaunch")
        app.open(URL(string: "anyprogress://ring/0")!)
        XCTAssertEqual(field.value as? String, "Morning recovery with a personal name")
        app.buttons["clearRingName"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(metric.waitForExistence(timeout: 5))
        XCTAssertTrue(metric.label.contains("HRV"))
        XCTAssertFalse(metric.label.contains("Morning recovery"))
    }

    @MainActor
    func testCustomNameAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.open(URL(string: "anyprogress://ring/0")!)
        let field = app.textFields["ringName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Personal recovery goal for every morning beyond the limit")
        app.buttons["Done"].tap()
        XCTAssertEqual(field.value as? String, "Personal recovery goal for every morning")
        capture(app, name: "Accessibility size custom name editor")
        app.terminate()
        app.launchArguments += ["--preserve-test-settings"]
        app.launch()
        let metric = app.descendants(matching: .any)["metric.0"]
        for _ in 0..<4 { if metric.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(metric.label.contains("Personal recovery goal for every morning"))
        capture(app, name: "Accessibility size custom name dashboard")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
