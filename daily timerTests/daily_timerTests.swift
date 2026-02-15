//
//  daily_timerTests.swift
//  daily timerTests
//
//  Created by Vitalii Kolmakov on 08.04.25.
//

import Foundation
import XCTest
@testable import daily_timer

final class DailyTimerTests: XCTestCase {
    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "daily-timer-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testLoadDefaultsWhenNoSavedUsers() {
        let defaults = makeIsolatedDefaults()
        let manager = UserManager(defaults: defaults, storageKey: "userList-test")

        XCTAssertEqual(manager.users.count, 3)
        XCTAssertEqual(manager.users.map(\.name), ["Alice", "Bob", "Charlie"])
    }

    func testSaveAndReloadUsersRoundTrip() {
        let defaults = makeIsolatedDefaults()
        let key = "userList-test"

        var manager = UserManager(defaults: defaults, storageKey: key)
        manager.users = [
            User(name: "Diana", isSelected: true, isFinalizer: false),
            User(name: "Evan", isSelected: false, isFinalizer: true)
        ]
        manager.saveUsers()

        manager = UserManager(defaults: defaults, storageKey: key)
        XCTAssertEqual(manager.users.count, 2)
        XCTAssertEqual(manager.users[0].name, "Diana")
        XCTAssertTrue(manager.users[1].isFinalizer)
    }

    func testSessionUsersKeepFinalizersAtEndAndSkipUnselected() {
        let users = [
            User(name: "A", isSelected: true, isFinalizer: false),
            User(name: "B", isSelected: false, isFinalizer: false),
            User(name: "C", isSelected: true, isFinalizer: true),
            User(name: "D", isSelected: true, isFinalizer: false),
            User(name: "E", isSelected: true, isFinalizer: true)
        ]

        let session = UserManager.makeSessionUsers(from: users)

        XCTAssertEqual(session.count, 4)
        XCTAssertFalse(session.contains(where: { $0.name == "B" }))

        XCTAssertNotNil(session.firstIndex(where: \.isFinalizer))
        if let firstFinalizer = session.firstIndex(where: \.isFinalizer) {
            XCTAssertTrue(session[firstFinalizer...].allSatisfy(\.isFinalizer))
        }
    }
}
