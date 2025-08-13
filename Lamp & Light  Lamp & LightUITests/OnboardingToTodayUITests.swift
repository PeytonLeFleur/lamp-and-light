import XCTest

final class OnboardingToTodayUITests: XCTestCase {
    func testOnboardingToToday() {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: ["-uiTesting", "1"])
        app.launch()

        if app.textFields["Name"].exists {
            app.textFields["Name"].tap()
            app.textFields["Name"].typeText("Alex")
        }
        if app.buttons["Start"].exists { app.buttons["Start"].tap() }

        // Avoid purchases in CI
        if app.buttons.matching(identifier: "Start Premium").firstMatch.exists {
            // Do not interact with purchases in UI tests
        }

        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Scripture'"))
            .firstMatch.waitForExistence(timeout: 15))
    }
} 