import XCTest

/// Developer tool: walks through screens and attaches screenshots to the test
/// result. Depends on whatever data is in the simulator, so it only runs when
/// TRAVELTIPS_SCREENSHOT_TOUR is set (pass TEST_RUNNER_TRAVELTIPS_SCREENSHOT_TOUR=1
/// to xcodebuild). Optional TRAVELTIPS_TOUR_TRIP picks the trip to open.
final class ScreenshotTour: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TRAVELTIPS_SCREENSHOT_TOUR"] != nil,
                          "Screenshot tour disabled")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testTour() throws {
        let app = XCUIApplication()
        app.launch()
        let tripName = ProcessInfo.processInfo.environment["TRAVELTIPS_TOUR_TRIP"] ?? "Spain"

        let trip = app.staticTexts[tripName].firstMatch
        XCTAssertTrue(trip.waitForExistence(timeout: 10))
        snap(app, "01-trips")

        trip.tap()
        XCTAssertTrue(app.staticTexts["Daily Overview"].firstMatch.waitForExistence(timeout: 5)
                      || app.staticTexts["DAILY OVERVIEW"].firstMatch.waitForExistence(timeout: 1))
        // Let the scroll-to-today animation finish.
        _ = app.staticTexts["TODAY"].firstMatch.waitForExistence(timeout: 3)
        snap(app, "02-overview")

        // Settings: turn notifications on and accept the system prompt.
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'My Trips'")).firstMatch.tap()
        let settingsTab = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if toggle.value as? String == "0" {
            toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: 5) { allow.tap() }
        }
        app.swipeUp()
        let refresh = app.buttons["Refresh"].firstMatch
        if refresh.waitForExistence(timeout: 3) { refresh.tap() }
        _ = app.staticTexts["pendingNotificationCount"].waitForExistence(timeout: 3)
        snap(app, "03-settings-notifications")
    }
}
