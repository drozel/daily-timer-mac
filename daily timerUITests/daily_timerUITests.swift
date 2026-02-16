//
//  daily_timerUITests.swift
//  daily timerUITests
//
//  Created by Vitalii Kolmakov on 08.04.25.
//

import XCTest

final class daily_timerUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMainWindowLayoutForMultipleUserCounts() throws {
        for userCount in [1, 5, 10, 50, 100] {
            let app = XCUIApplication()
            app.launchEnvironment["UITEST_USER_COUNT"] = "\(userCount)"
            app.launchEnvironment["UITEST_APPEARANCE"] = "light"
            app.launch()

            XCTAssertTrue(app.staticTexts["Teammates"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["START"].waitForExistence(timeout: 5))

            XCTAssertTrue(waitForUserRow("User 1", in: app, timeout: 6))

            let targetUserLabel = "User \(userCount)"
            if userCount <= 10 {
                XCTAssertTrue(waitForUserRow(targetUserLabel, in: app, timeout: 6))
            } else {
                XCTAssertTrue(scrollToUserRow(targetUserLabel, in: app, maxSwipes: 10), "Expected to find \(targetUserLabel)")
            }

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Main Window - \(userCount) users"
            attachment.lifetime = .keepAlways
            add(attachment)

            app.terminate()
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func userRowElement(_ userName: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons["userRow-\(userName)"]
    }

    private func waitForUserRow(_ label: String, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if userRowExists(label, in: app) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }

    private func userRowExists(_ label: String, in app: XCUIApplication) -> Bool {
        userRowElement(label, in: app).exists
    }

    private func scrollToUserRow(_ label: String, in app: XCUIApplication, maxSwipes: Int) -> Bool {
        if userRowExists(label, in: app) {
            return true
        }
        let scrollView = app.scrollViews["usersScrollView"]
        guard scrollView.exists else { return false }

        for _ in 0..<maxSwipes {
            scrollView.swipeDown()
            if userRowExists(label, in: app) {
                return true
            }
        }

        return false
    }
}
