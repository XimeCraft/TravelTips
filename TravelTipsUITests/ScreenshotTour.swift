import XCTest

/// Developer tool: walks through screens and attaches screenshots to the test
/// result. Depends on whatever data is in the simulator, so it only runs when
/// TRAVELTIPS_SCREENSHOT_TOUR is set (pass TEST_RUNNER_TRAVELTIPS_SCREENSHOT_TOUR=1
/// to xcodebuild). Optional TRAVELTIPS_TOUR_TRIP picks the trip to open, and
/// TRAVELTIPS_TOUR_LANG=zh-Hans runs the app in Chinese.
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
        let env = ProcessInfo.processInfo.environment
        let zh = env["TRAVELTIPS_TOUR_LANG"] == "zh-Hans"
        let L: (String, String) -> String = { en, cn in zh ? cn : en }

        let app = XCUIApplication()
        if zh { app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"] }
        app.launch()
        let tripName = env["TRAVELTIPS_TOUR_TRIP"] ?? "Spain"

        let trip = app.staticTexts[tripName].firstMatch
        XCTAssertTrue(trip.waitForExistence(timeout: 10))
        snap(app, "01-trips")

        trip.tap()
        XCTAssertTrue(app.buttons[L("Overview", "概览")].firstMatch.waitForExistence(timeout: 5))
        // Let the scroll-to-today animation finish.
        _ = app.staticTexts[L("TODAY", "今天")].firstMatch.waitForExistence(timeout: 3)
        snap(app, "02-overview")

        // Settings: turn notifications on and accept the system prompt.
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", L("My Trips", "我的行程"))).firstMatch.tap()
        let settingsTab = app.buttons[L("Settings", "设置")].firstMatch
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if toggle.value as? String == "0" {
            toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons[L("Allow", "允许")]
            if allow.waitForExistence(timeout: 5) { allow.tap() }
        }
        app.swipeUp()
        // Debug card: refresh until the queued count settles (scheduling is async).
        let refresh = app.buttons[L("Refresh", "刷新")].firstMatch
        let count = app.staticTexts["pendingNotificationCount"].firstMatch
        if refresh.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                refresh.tap()
                if count.waitForExistence(timeout: 1), !count.label.hasSuffix(": 0") { break }
            }
        }
        snap(app, "03-settings-notifications")
    }
}
