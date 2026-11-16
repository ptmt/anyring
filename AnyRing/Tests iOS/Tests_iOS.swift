import XCTest
import UIKit

final class Tests_iOS: XCTestCase {
    @MainActor
    func testSavedConfigurationStripRestoresCompleteSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--legacy-template-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let save = app.buttons["saveConfiguration"]
        XCTAssertTrue(save.waitForExistence(timeout: 10), "Saved configurations must be reachable beside the graph")
        guard save.exists else { return }
        save.tap()
        app.textFields["Template name"].typeText("Recovery")
        app.alerts.buttons["Save"].tap()
        let preset = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'savedConfiguration.'")).firstMatch
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        XCTAssertTrue(preset.isSelected)
        capture(app, name: "Saved complete configuration synthetic")
        app.buttons["trackingPeriod"].tap()
        app.buttons["7 days"].tap()
        let shape = app.buttons["visualizationShape"]
        for _ in 0..<6 { if shape.isHittable { break }; app.swipeUp() }
        shape.tap()
        app.buttons["shape.circle"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        let firstRing = app.buttons["ring1"]
        for _ in 0..<6 { if firstRing.isHittable { break }; app.swipeUp() }
        firstRing.tap()
        app.buttons["Heart-rate"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Step count'")).firstMatch.tap()
        XCTAssertEqual((app.textFields["goal"].value as? String)?.replacingOccurrences(of: ",", with: ""), "8000")
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<8 { if preset.isHittable { break }; app.swipeDown() }
        XCTAssertFalse(preset.isSelected)
        preset.tap()
        app.alerts.buttons["Use template"].tap()
        for _ in 0..<8 { if app.buttons["trackingPeriod"].isHittable { break }; app.swipeDown() }
        XCTAssertEqual(app.buttons["trackingPeriod"].value as? String, "5 days")
        XCTAssertTrue(preset.isSelected)
        app.terminate()
        app.launchArguments += ["--preserve-test-settings"]
        app.launch()
        XCTAssertTrue(preset.waitForExistence(timeout: 10))
        XCTAssertTrue(preset.isSelected)
        capture(app, name: "Saved configuration cold relaunch synthetic")
        for _ in 0..<6 { if shape.isHittable { break }; app.swipeUp() }
        shape.tap()
        XCTAssertTrue(app.buttons["shape.rectangular"].isSelected)
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<6 { if firstRing.isHittable { break }; app.swipeUp() }
        firstRing.tap()
        XCTAssertTrue(app.buttons["Heart-rate"].exists)
        XCTAssertEqual(app.textFields["ringName"].value as? String, "Resting")
        XCTAssertEqual(app.textFields["goal"].value as? String, "35")
        XCTAssertEqual(app.textFields["startFrom"].value as? String, "60")
        capture(app, name: "Restored saved source goal baseline name synthetic")
    }
    @MainActor
    func testNeutralPeriodLabelAndRenderedColors() throws {
        let app = XCUIApplication()
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-UIPreferredContentSizeCategoryName", category]
            app.launch()
            let period = app.buttons["trackingPeriod"]
            XCTAssertTrue(period.waitForExistence(timeout: 10))
            XCTAssertEqual(period.label, "Period")
            XCTAssertEqual(period.value as? String, "3 days")
            XCTAssertGreaterThanOrEqual(period.frame.height, 44)
            let week = app.descendants(matching: .any)["trackingWeek"].firstMatch
            XCTAssertTrue(week.exists)
            // The adaptive dashboard stacks metrics above this control at large text.
            // Bring both measured regions on-screen before inspecting screenshot pixels.
            for _ in 0..<8 {
                if period.isHittable && period.frame.minY >= 0 && week.frame.maxY < app.frame.maxY - 20 { break }
                app.swipeUp()
            }
            XCTAssertGreaterThanOrEqual(period.frame.minY, 0)
            XCTAssertLessThan(week.frame.maxY, app.frame.maxY - 20)
            capture(app, name: "Neutral period \(category) synthetic")
            // Inspect the real rendered control and date strip, not Color values.
            let image = try XCTUnwrap(app.screenshot().image.cgImage)
            let scale = CGFloat(image.width) / app.frame.width
            let weekRect = CGRect(x: period.frame.minX, y: week.frame.minY, width: period.frame.width, height: week.frame.height)
            XCTAssertGreaterThan(weekRect.height, 40)
            for (name, rect) in [("period", period.frame), ("week", weekRect)] {
                let crop = try XCTUnwrap(image.cropping(to: CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale)))
                var bytes = [UInt8](repeating: 0, count: crop.width * crop.height * 4)
                let context = try XCTUnwrap(CGContext(data: &bytes, width: crop.width, height: crop.height, bitsPerComponent: 8, bytesPerRow: crop.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
                let chromatic = stride(from: 0, to: bytes.count, by: 4).filter { i in
                    Int(max(bytes[i], bytes[i + 1], bytes[i + 2])) - Int(min(bytes[i], bytes[i + 1], bytes[i + 2])) > 8
                }.count
                XCTAssertEqual(chromatic, 0, "\(name) must use neutral rendered pixels")
            }
            period.tap()
            XCTAssertTrue(app.buttons["3 days"].waitForExistence(timeout: 5))
            sleep(1) // Capture the settled native menu, not its opening transition.
            capture(app, name: "Neutral period checked menu \(category) synthetic")
            app.buttons["5 days"].tap()
            XCTAssertEqual(period.value as? String, "5 days")
            app.terminate()
        }
    }

    @MainActor
    func testCompactDashboardInlinePeriodAndAppearance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--refresh-probe", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let period = app.buttons["trackingPeriod"]
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        guard period.exists else { return }
        XCTAssertFalse(app.staticTexts["AnyProgress"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'is better'")).firstMatch.exists)
        XCTAssertGreaterThanOrEqual(period.frame.height, 44)
        capture(app, name: "Compact dashboard three days synthetic")
        let probe = app.descendants(matching: .any)["refreshVerification"]
        func readCount() -> Double { Double((probe.value as? String ?? "").split(separator: ",").first ?? "") ?? 0 }
        sleep(2)
        let before = readCount()
        period.tap()
        app.buttons["5 days"].tap()
        let queried = NSPredicate { _, _ in readCount() == before + 6 }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: queried, object: nil)], timeout: 10) == .completed)
        XCTAssertEqual(period.value as? String, "5 days")
        capture(app, name: "Compact dashboard five days synthetic")
        let beforeForeground = readCount()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        let foregroundQueried = NSPredicate { _, _ in readCount() >= beforeForeground + 6 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: foregroundQueried, object: nil)], timeout: 10), .completed)
        XCTAssertEqual(period.value as? String, "5 days")
        app.terminate()
        app.launchArguments += ["--preserve-test-settings"]
        app.launch()
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        XCTAssertEqual(period.value as? String, "5 days")
        let shape = app.buttons["visualizationShape"]
        for _ in 0..<8 { if shape.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Appearance"].exists)
        XCTAssertFalse(app.staticTexts["Visualization"].exists)
        XCTAssertFalse(app.staticTexts["Color Palettes"].exists)
        capture(app, name: "Unified appearance synthetic")
        shape.tap()
        app.buttons["shape.circle"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        let palette = app.buttons["palette.Aurora"]
        for _ in 0..<6 { if palette.isHittable { break }; app.swipeUp() }
        palette.tap()
        XCTAssertTrue(palette.isSelected)
        capture(app, name: "Selected appearance synthetic")
        app.terminate()
        app.launch()
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        XCTAssertEqual(period.value as? String, "5 days")
        for _ in 0..<8 { if palette.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(palette.isSelected, "Palette must survive a cold relaunch")
        shape.tap()
        XCTAssertTrue(app.buttons["shape.circle"].isSelected, "Shape must survive a cold relaunch")
        capture(app, name: "Persisted appearance after cold relaunch synthetic")
    }

    @MainActor
    func testCompactDashboardFrenchLargeTypeAndKeyboard() {
        let app = XCUIApplication()
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            app.launchArguments = ["--ui-testing", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR", "-UIPreferredContentSizeCategoryName", category]
            app.launch()
            let period = app.buttons["trackingPeriod"]
            XCTAssertTrue(period.waitForExistence(timeout: 10))
            capture(app, name: "Compact French \(category)")
            let metric = app.descendants(matching: .any)["metric.2"]
            for _ in 0..<8 { if metric.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(metric.isHittable)
            XCTAssertTrue(metric.label.contains("Goal ≥"))
            capture(app, name: "Metrics French \(category)")
            app.open(URL(string: "anyprogress://ring/0")!)
            let field = app.textFields["ringName"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.tap()
            field.typeText("Récupération")
            capture(app, name: "Keyboard French \(category)")
            app.terminate()
        }
    }

    @MainActor
    func testWorkoutZoneMetricsSelectionMinutesNamesAndRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--workout-zone-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        func openRing(_ index: Int) {
            let button = app.buttons["ring\(index)"]
            for _ in 0..<8 { if button.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            button.tap()
        }
        for (index, name, label) in [(1, "Heart rate zones 2–3", "Easy training"), (2, "Heart rate zones 4–5", "Hard training")] {
            openRing(index)
            app.buttons[index == 1 ? "HRV" : "Step count"].tap()
            let metric = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
            XCTAssertTrue(metric.waitForExistence(timeout: 5))
            metric.tap()
            XCTAssertTrue(app.textFields["goal"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.switches["Reversed Direction"].exists)
            XCTAssertFalse(app.buttons["Aggregation"].exists)
            let goal = app.textFields["goal"]
            goal.tap()
            goal.press(forDuration: 1.2)
            let selectAll = app.buttons["Select All"]
            if selectAll.waitForExistence(timeout: 3) { selectAll.tap() }
            else {
                goal.doubleTap()
                let select = app.buttons["Select"]
                if select.waitForExistence(timeout: 2) { select.tap() }
            }
            goal.typeText("45")
            let nameField = app.textFields["ringName"]
            nameField.tap()
            nameField.typeText(label + "\n")
            capture(app, name: name + " editor minutes")
            app.navigationBars.buttons.firstMatch.tap()
        }
        let period = app.buttons["trackingPeriod"]
        for _ in 0..<8 { if period.isHittable { break }; app.swipeUp() }
        period.tap()
        app.buttons["5 days"].tap()
        for _ in 0..<8 { if app.buttons["ring1"].isHittable { break }; app.swipeDown() }
        capture(app, name: "Workout zone dashboard synthetic")
        app.terminate()
        app.launchArguments += ["--preserve-test-settings"]
        app.launch()
        openRing(1)
        XCTAssertTrue(app.buttons["Heart rate zones 2–3"].exists)
        XCTAssertEqual(app.textFields["ringName"].value as? String, "Easy training")
        XCTAssertEqual(app.textFields["goal"].value as? String, "45")
        capture(app, name: "Workout zones restored")
    }
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
        XCTAssertTrue(app.buttons["trackingPeriod"].waitForExistence(timeout: 5))
        app.open(URL(string: "anyprogress://rings")!)
        XCTAssertTrue(app.buttons["trackingPeriod"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardAndMetricEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["trackingPeriod"].waitForExistence(timeout: 10))
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
        let period = app.buttons["trackingPeriod"]
        for _ in 0..<6 {
            if period.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        period.tap()
        app.buttons["7 days"].tap()
        app.terminate()
        // Keep fixtures explicit on relaunch without clearing persisted settings.
        app.launchArguments = ["--ui-testing", "--preserve-test-settings"]
        app.launch()
        for _ in 0..<6 {
            if period.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(period.waitForExistence(timeout: 5))
        XCTAssertEqual(period.value as? String, "7 days")
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
