import SwiftUI

struct User: Identifiable, Codable {
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

    init() {
        loadUsers()
    }

    func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: "userList"),
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
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: "userList")
        }
    }
}
