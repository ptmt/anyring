import XCTest
import UIKit

final class Tests_iOS: XCTestCase {
    @MainActor
    func testSavedSelectionKeepsNativeGeometry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--saved-selection-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let names = ["hrv/steps/hr", "zones", "swim"]
        let cards = names.indices.map { app.buttons["savedConfiguration.00000000-0000-0000-0000-00000000000\($0 + 1)"] }
        XCTAssertTrue(cards[2].waitForExistence(timeout: 10))
        let probe = app.staticTexts["savedSelectionGeometry"]
        XCTAssertTrue(probe.waitForExistence(timeout: 5))
        func frames() throws -> [String: [Double]] {
            try JSONDecoder().decode([String: [Double]].self, from: Data(probe.label.utf8))
        }
        let initial = try frames()
        XCTAssertEqual(initial.count, 10)
        let row = app.cells.containing(.button, identifier: "saveConfiguration").firstMatch
        let initialRow = row.frame
        let saveFrame = app.buttons["saveConfiguration"].frame
        for selected in [2, 0, 1, 2] {
            cards[selected].tap()
            XCTAssertTrue(cards[selected].isSelected, "Selection must compare the entire saved configuration")
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'savedConfiguration.'")).count, 3)
            let current = try frames()
            let attachment = XCTAttachment(string: "selected=\(names[selected]) row=\(row.frame) frames=\(probe.label)")
            attachment.name = "Saved selection geometry \(names[selected])"; attachment.lifetime = .keepAlways; add(attachment)
            capture(app, name: "Saved selection \(names[selected]) synthetic")
            XCTAssertEqual(row.frame, initialRow, "Selection cannot resize or move its Form row")
            XCTAssertEqual(app.buttons["saveConfiguration"].frame, saveFrame)
            XCTAssertLessThanOrEqual(row.frame.height, 177)
            for name in names {
                for part in ["item", "preview", "title"] {
                    let key = "\(part).\(name)"
                    let before = try XCTUnwrap(initial[key]); let after = try XCTUnwrap(current[key])
                    for axis in 0..<4 { XCTAssertEqual(after[axis], before[axis], accuracy: 0.34, "\(key) axis \(axis) moved on selection") }
                }
                let item = try XCTUnwrap(current["item.\(name)"])
                XCTAssertGreaterThanOrEqual(item[2], 44); XCTAssertGreaterThanOrEqual(item[3], 44)
                XCTAssertEqual(try XCTUnwrap(current["preview.\(name)"])[1], try XCTUnwrap(current["preview.hrv/steps/hr"])[1], accuracy: 0.34)
                XCTAssertEqual(try XCTUnwrap(current["title.\(name)"])[1], try XCTUnwrap(current["title.hrv/steps/hr"])[1], accuracy: 0.34)
            }
            for i in names.indices {
                XCTAssertEqual(cards[i].isSelected, i == selected)
                XCTAssertGreaterThanOrEqual(cards[i].frame.width, 44)
                XCTAssertGreaterThanOrEqual(cards[i].frame.height, 44)
            }
            app.terminate()
            if !app.launchArguments.contains("--preserve-test-settings") { app.launchArguments += ["--preserve-test-settings"] }
            app.launch()
            XCTAssertTrue(cards[selected].waitForExistence(timeout: 10))
            XCTAssertTrue(cards[selected].isSelected, "Full configuration and saved identity must survive cold launch")
        }
    }

    @MainActor
    func testSavedSelectionAccessibilityTitlesFit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--saved-selection-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let save = app.buttons["saveConfiguration"]
        for _ in 0..<12 {
            if save.exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let row = app.cells.containing(.button, identifier: "saveConfiguration").firstMatch
        for _ in 0..<20 {
            if row.frame.minY >= 70 && row.frame.maxY <= app.frame.maxY - 20 { break }
            let up = row.frame.maxY > app.frame.maxY - 20
            let distance = min(180, max(30, (up ? row.frame.maxY - (app.frame.maxY - 24) : 74 - row.frame.minY) + 10))
            let y = app.frame.height * (up ? 0.7 : 0.35)
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.midX, dy: y))
                .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: app.frame.midX, dy: y + (up ? -distance : distance))),
                       withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        XCTAssertGreaterThanOrEqual(row.frame.minY, 70)
        XCTAssertLessThanOrEqual(row.frame.maxY, app.frame.maxY - 20)
        let names = ["hrv/steps/hr", "zones", "swim"]
        let probe = app.staticTexts["savedSelectionGeometry"]
        for i in names.indices {
            let card = app.buttons["savedConfiguration.00000000-0000-0000-0000-00000000000\(i + 1)"]
            for _ in 0..<8 {
                if card.frame.minX >= 32 && card.frame.maxX <= app.frame.maxX - 32 { break }
                let right = card.frame.minX < 32
                // Account for the native pan recognizer's movement threshold; a
                // 10pt correction can be treated as a stationary press.
                let distance = min(180, max(30, (right ? 36 - card.frame.minX : card.frame.maxX - (app.frame.maxX - 36)) + 10))
                let start = CGPoint(x: right ? 80 : app.frame.width - 80, y: card.frame.midY)
                let end = CGPoint(x: start.x + (right ? distance : -distance), y: start.y)
                app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: start.x, dy: start.y))
                    .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: end.x, dy: end.y)),
                           withVelocity: .slow, thenHoldForDuration: 0.5)
            }
            XCTAssertTrue(card.isHittable)
            XCTAssertGreaterThanOrEqual(card.frame.minX, 32)
            XCTAssertLessThanOrEqual(card.frame.maxX, app.frame.maxX - 32)
            card.tap()
            XCTAssertTrue(card.isSelected)
            let frames = try JSONDecoder().decode([String: [Double]].self, from: Data(probe.label.utf8))
            let item = try XCTUnwrap(frames["item.\(names[i])"])
            let title = try XCTUnwrap(frames["title.\(names[i])"])
            let font = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
            let measured = (names[i] as NSString).boundingRect(with: CGSize(width: title[2], height: 1000),
                options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
            XCTAssertLessThanOrEqual(measured.height, title[3] + 1, "The complete template name must fit")
            XCTAssertGreaterThanOrEqual(title[0], item[0]); XCTAssertGreaterThanOrEqual(title[1], item[1])
            XCTAssertLessThanOrEqual(title[0] + title[2], item[0] + item[2])
            XCTAssertLessThanOrEqual(title[1] + title[3], item[1] + item[3])
            XCTAssertGreaterThanOrEqual(card.frame.height, 44)
            capture(app, name: "Saved selection accessibility \(i) synthetic")
        }
    }

    @MainActor
    func testIncludedWeekRangeBackgroundPresets() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--dashboard-density-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let period = app.buttons["trackingPeriod"]
        XCTAssertTrue(period.waitForExistence(timeout: 10))
        var initialWeek: CGRect?
        for count in [3, 1, 2, 5, 7] {
            period.tap()
            let choice = app.buttons[count == 1 ? "1 day" : "\(count) days"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            choice.tap()
            XCTAssertEqual(period.value as? String, count == 1 ? "1 day" : "\(count) days")
            let cells = app.descendants(matching: .any).matching(NSPredicate(format: "value IN %@", ["Included", "Not included", "Today, Included"]))
                .allElementsBoundByIndex.sorted { $0.frame.minX < $1.frame.minX }
            XCTAssertEqual(cells.count, 7)
            guard cells.count == 7 else { return }
            let contentFrames = cells.map(\.frame)
            // SwiftUI exposes each ignored-child AX element's text bounds, not
            // its equal-width padded calendar cell. Recover the rendered grid
            // from the native Period width and the existing 5pt vertical padding.
            let week = CGRect(x: period.frame.minX, y: contentFrames[0].minY - 5,
                              width: period.frame.width, height: contentFrames[0].height + 10)
            let frames = (0..<7).map { index in
                CGRect(x: week.minX + CGFloat(index) * week.width / 7, y: week.minY,
                       width: week.width / 7, height: week.height)
            }
            if let initialWeek {
                XCTAssertEqual(week.minY, initialWeek.minY, accuracy: 0.01)
                XCTAssertEqual(week.width, initialWeek.width, accuracy: 0.01)
                XCTAssertEqual(week.height, initialWeek.height, accuracy: 0.01, "Changing the range must not change layout")
            } else { initialWeek = week }
            XCTAssertTrue((cells[6].value as? String)?.contains("Today, Included") == true)
            XCTAssertLessThan(week.maxY, app.frame.maxY - 20)
            capture(app, name: "Included range \(count) days synthetic")
            let image = try XCTUnwrap(app.screenshot().image.cgImage)
            let scale = CGFloat(image.width) / app.frame.width
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            let context = try XCTUnwrap(CGContext(data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            func gray(_ x: CGFloat, _ y: CGFloat) -> Int {
                let i = (Int(y * scale) * image.width + Int(x * scale)) * 4
                XCTAssertLessThanOrEqual(Int(max(bytes[i], bytes[i+1], bytes[i+2])) - Int(min(bytes[i], bytes[i+1], bytes[i+2])), 2)
                return Int(bytes[i])
            }
            let outside = gray(week.midX, week.minY - 2)
            let fill = gray(frames[6].midX, week.minY + 2)
            XCTAssertGreaterThan(abs(fill - outside), 8, "Included dates need a visible neutral background")
            XCTAssertLessThan(abs(fill - outside), 50, "Range background must stay low emphasis")
            for (index, frame) in frames.enumerated() {
                let included = index >= 7 - count
                XCTAssertTrue(frame.insetBy(dx: -0.01, dy: -0.01).contains(contentFrames[index]), "The complete date and Today label must fit inside their cell")
                XCTAssertEqual(cells[index].value as? String, index == 6 ? "Today, Included" : (included ? "Included" : "Not included"))
                XCTAssertEqual(gray(frame.midX, week.minY + 2), included ? fill : outside, accuracy: 2)
                if index > 7 - count {
                    XCTAssertEqual(gray(frame.minX, week.minY + 2), fill, accuracy: 2, "No gap or rounded internal seam")
                }
            }
            for x in [frames[7-count].minX + 1, week.maxX - 1] {
                XCTAssertEqual(gray(x, week.minY + 1), outside, accuracy: 2, "Only the range ends are rounded")
                XCTAssertEqual(gray(x, week.maxY - 1), outside, accuracy: 2)
            }
            let evidence = XCTAttachment(string: "count=\(count) week=\(week) cells=\(frames) fill=\(fill) outside=\(outside)")
            evidence.name = "Included range geometry \(count)"; evidence.lifetime = .keepAlways; add(evidence)
        }
    }

    @MainActor
    func testDashboardDensityEmptyAndSavedRows() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--dashboard-density-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let save = app.buttons["saveConfiguration"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        guard save.exists else { return }
        let emptyRow = app.cells.containing(.button, identifier: "saveConfiguration").firstMatch
        let dashboard = app.cells.containing(.button, identifier: "trackingPeriod").firstMatch
        XCTAssertTrue(emptyRow.exists)
        XCTAssertTrue(dashboard.exists)
        guard emptyRow.exists, dashboard.exists else { return }
        capture(app, name: "Density empty library synthetic")
        func record(_ state: String, _ row: XCUIElement) {
            let evidence = XCTAttachment(string: "state=\(state) viewport=\(app.frame) dashboard=\(dashboard.frame) savedRow=\(row.frame) save=\(save.frame)")
            evidence.name = "Density geometry \(state)"
            evidence.lifetime = .keepAlways
            add(evidence)
        }
        record("empty", emptyRow)
        XCTAssertGreaterThanOrEqual(save.frame.height, 44)
        XCTAssertLessThanOrEqual(emptyRow.frame.height, 80, "Empty library must be one intrinsic save row, not a reserved carousel")
        XCTAssertTrue(app.buttons["visualizationShape"].isHittable, "Appearance must be visible on the first ordinary-size screen")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'savedConfiguration.'")).count, 0)
        save.tap()
        app.textFields["Template name"].typeText("Daily setup")
        app.alerts.buttons["Save"].tap()
        let preset = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'savedConfiguration.'")).firstMatch
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        XCTAssertTrue(preset.isSelected)
        let filledRow = app.cells.containing(.button, identifier: "saveConfiguration").firstMatch
        record("filled", filledRow)
        capture(app, name: "Density saved library synthetic")
        XCTAssertLessThanOrEqual(filledRow.frame.height, 200, "The populated strip must fit its real thumbnails")
        preset.press(forDuration: 1)
        app.buttons["Rename"].tap()
        let name = app.textFields["Template name"]
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Daily setup".count) + "Recovery")
        app.alerts.buttons["Save"].tap()
        XCTAssertEqual(preset.label, "Recovery")
        preset.press(forDuration: 1)
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.alerts["Delete template?"].exists)
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(preset.exists)
        preset.press(forDuration: 1)
        app.buttons["Delete"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'savedConfiguration.'")).count, 0)
        XCTAssertLessThanOrEqual(emptyRow.frame.height, 80)
        capture(app, name: "Density empty after confirmed deletion synthetic")
    }

    @MainActor
    func testDashboardDensityAccessibilityContent() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--dashboard-density-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for (index, expected) in [(0, "HRV"), (1, "Step count"), (2, "Heart-rate")] {
            let metric = app.descendants(matching: .any)["metric.\(index)"]
            XCTAssertTrue(metric.waitForExistence(timeout: 10))
            for _ in 0..<8 {
                if metric.isHittable && metric.frame.minY >= 70 && metric.frame.maxY <= app.frame.maxY - 20 { break }
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                    .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            }
            XCTAssertTrue(metric.isHittable)
            XCTAssertGreaterThanOrEqual(metric.frame.minY, 70)
            XCTAssertLessThanOrEqual(metric.frame.maxY, app.frame.maxY - 20)
            XCTAssertTrue(metric.label.contains(expected))
            XCTAssertTrue(metric.label.contains("Goal"))
            if index == 2 {
                XCTAssertTrue(metric.label.contains("55 bpm"))
                XCTAssertTrue(metric.label.contains("Goal ≤ 42 bpm"))
                XCTAssertTrue(metric.label.contains("Lower is better"))
                XCTAssertTrue(metric.label.contains("From 80 bpm"))
                XCTAssertFalse(metric.label.contains("Goal ≤ 80 bpm"))
            }
            XCTAssertGreaterThanOrEqual(metric.frame.minX, 0)
            XCTAssertLessThanOrEqual(metric.frame.maxX, app.frame.maxX)
            capture(app, name: "Density accessibility metric \(index) synthetic")
        }
        let save = app.buttons["saveConfiguration"]
        for _ in 0..<8 {
            if save.isHittable && save.frame.minY >= 70 && save.frame.maxY <= app.frame.maxY - 20 { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }
        XCTAssertTrue(save.isHittable)
        XCTAssertGreaterThanOrEqual(save.frame.minY, 70)
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY - 20)
        XCTAssertEqual(save.label, "Save current setup")
        XCTAssertGreaterThanOrEqual(save.frame.height, 44)
        XCTAssertLessThanOrEqual(save.frame.maxX, app.frame.maxX)
        capture(app, name: "Density accessibility empty footer synthetic")
    }

    @MainActor
    func testSavedConfigurationStripRestoresCompleteSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--legacy-template-fixture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let save = app.buttons["saveConfiguration"]
        XCTAssertTrue(save.waitForExistence(timeout: 10), "Saved configurations must be reachable beside the graph")
        guard save.exists else { return }
        XCTAssertTrue(save.isHittable)
        save.tap()
        let naming = app.alerts["Save template"]
        XCTAssertTrue(naming.waitForExistence(timeout: 5), "The actual plus control must open the naming dialog")
        let name = naming.textFields["Template name"]
        let saveName = naming.buttons["Save"]
        XCTAssertFalse(saveName.isEnabled, "Empty names cannot create a template")
        name.tap()
        name.typeText("   ")
        XCTAssertFalse(saveName.isEnabled, "Whitespace-only names cannot create a template")
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "Recovery")
        XCTAssertTrue(saveName.isEnabled, "Typing a valid name must enable Save immediately")
        saveName.tap()
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
            if category == "UICTContentSizeCategoryAccessibilityXXXL" {
                let save = app.buttons["saveConfiguration"]
                XCTAssertTrue(save.exists)
                XCTAssertEqual(save.label, "Save current setup")
                XCTAssertGreaterThanOrEqual(save.frame.height, 44)
                XCTAssertLessThanOrEqual(save.frame.maxX, app.frame.maxX,
                                         "The empty-state action must wrap without clipping at accessibility sizes")
            }
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
        // Returning from the lower metric editors retains the list offset.
        // Period is above those rows; scrolling farther down virtualizes it away.
        for _ in 0..<8 { if period.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(period.isHittable)
        period.tap()
        app.buttons["5 days"].tap()
        XCTAssertEqual(period.value as? String, "5 days")
        for _ in 0..<8 { if app.buttons["ring1"].isHittable { break }; app.swipeUp() }
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
