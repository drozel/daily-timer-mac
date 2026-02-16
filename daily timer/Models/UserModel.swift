import SwiftUI

struct User: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var isSelected: Bool
    var isFinalizer: Bool

    init(id: UUID = UUID(), name: String, isSelected: Bool, isFinalizer: Bool) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
        self.isFinalizer = isFinalizer
    }
}

class UserManager: ObservableObject {
    @Published var users: [User] = []
    private let defaults: UserDefaults
    private let storageKey: String
    private let processInfo: ProcessInfo

    init(defaults: UserDefaults = .standard, storageKey: String = "userList", processInfo: ProcessInfo = .processInfo) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.processInfo = processInfo
        loadUsers()
    }

    func loadUsers() {
        if let uiTestCount = processInfo.environment["UITEST_USER_COUNT"],
           let count = Int(uiTestCount), count > 0 {
            users = (1...count).map { index in
                User(name: "User \(index)", isSelected: true, isFinalizer: false)
            }
            return
        }

        if let data = defaults.data(forKey: storageKey),
           let savedUsers = try? JSONDecoder().decode([User].self, from: data) {
            users = savedUsers
        } else {
            users = [
                User(name: "Alice", isSelected: true, isFinalizer: false),
                User(name: "Bob", isSelected: true, isFinalizer: false),
                User(name: "Charlie", isSelected: true, isFinalizer: false)
            ]
        }
    }

    func saveUsers() {
        if processInfo.environment["UITEST_USER_COUNT"] != nil {
            return
        }
        if let data = try? JSONEncoder().encode(users) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func makeSessionUsers() -> [User] {
        Self.makeSessionUsers(from: users)
    }

    static func makeSessionUsers(from users: [User]) -> [User] {
        let selectedUsers = users.filter { $0.isSelected }
        let usualUsers = selectedUsers.filter { !$0.isFinalizer }.shuffled()
        let finalizerUsers = selectedUsers.filter { $0.isFinalizer }
        return usualUsers + finalizerUsers
    }
}
