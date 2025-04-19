import SwiftUI

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isSelected: Bool
    var isAdmin: Bool
    
    init(id: UUID = UUID(), name: String, isSelected: Bool, isAdmin: Bool) {
            self.id = id
            self.name = name
            self.isSelected = isSelected
            self.isAdmin = isAdmin
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
                User(name: "Alice", isSelected: true, isAdmin: false),
                User(name: "Bob", isSelected: true, isAdmin: false),
                User(name: "Charlie", isSelected: true, isAdmin: false)
            ]
        }
    }

    func saveUsers() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: "userList")
        }
    }
}

struct ContentView: View {
    @AppStorage("timerSeconds") private var timeout: Int = 90

    @StateObject var userManager = UserManager()
    @State private var currentUser: User? = nil
    @State private var timeRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var showEnd: Bool = false
    @State private var mode: Int = 1
    @State private var timer: Timer?

    var body: some View {
        VStack {
            if mode == 1 {
                Text("Daily time!")
                    .font(.title)
                
                List {
                    ForEach($userManager.users) { $user in
                        HStack {
                            Toggle(isOn: $user.isSelected) {
                                Text(user.name)
                            }
                            .onChange(of: user.isSelected) {
                                userManager.saveUsers()
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Timeout (seconds):")
                    TextField("90", value: $timeout, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
               Text("Teammates today: \(userManager.users.filter { $0.isSelected }.count)")
                   .font(.subheadline)
                   .padding(.top, 10)
               Text("Total time: \(calculateTotalTime()) minutes")
                   .font(.subheadline)
                
                HStack {
                    Button("START") {
                        startSession()
                    }
                    Button("Edit Users") {
                        mode = 3
                    }
                }
                .padding()
                .onAppear {
                    resizeWindowToFitUsers(count: userManager.users.count)
                }
            }
            else if mode == 2 {
                if let currentUser = currentUser {
                    VStack(spacing: 20) {
                        Text(currentUser.name)
                            .font(.system(size: 30, weight: .bold))
                        
                        if timeRemaining == 0 {
                           Image(systemName: "flame.fill")
                               .resizable()
                               .frame(width: 38, height: 38)
                               .foregroundColor(.red)
                       } else {
                           Text("\(timeRemaining)")
                               .font(.system(size: 38))
                               .foregroundColor(timeRemaining < 10 ? .red : .green)
                       }
                                                
                        Button(action: nextUser) {
                            Text("Next")
                        }
                        .padding()
                    }
                    .padding()
                } else if showEnd {
                    Text("END")
                        .font(.largeTitle)
                        .padding()
                    Button("EXIT") {
                        exit(0)
                    }
                    .padding()
                }
            }

            else if mode == 3 {
                EditUserView(userManager: userManager)
                Button("Back") {
                    userManager.saveUsers()
                    mode = 1
                }
                .padding()
            }
        }
        .padding()
    }

    func startSession() {
        let selectedUsers = userManager.users.filter { $0.isSelected }
        let nonAdminUsers = selectedUsers.filter { !$0.isAdmin }.shuffled()
        let adminUsers = selectedUsers.filter { $0.isAdmin }
        
        guard !selectedUsers.isEmpty else { return }

        userManager.users = nonAdminUsers + adminUsers
        currentUser = userManager.users.first
        timeRemaining = timeout
        resizeWindow(to: NSSize(width: 180, height: 220))
        mode = 2
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timeRemaining = timeout
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                // Display the bomb icon when time is up
                isTimerRunning = false
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        isTimerRunning = false
    }

    func nextUser() {
        stopTimer()
        
        if let currentIndex = userManager.users.firstIndex(where: { $0.id == currentUser?.id }) {
            if currentIndex + 1 < userManager.users.count {
                currentUser = userManager.users[currentIndex + 1]
                startTimer()
            } else {
                showEnd = true
                currentUser = nil
            }
        }
    }
    
    func resizeWindow(to size: NSSize) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.setContentSize(size)
                window.minSize = size
                window.maxSize = size
            }
        }
    }
    
    func resizeWindowToFitUsers(count: Int) {
        let rowHeight: CGFloat = 30   // Approximate height per row
        let baseHeight: CGFloat = 300 // Header + other UI elements
        let height = baseHeight + CGFloat(count) * rowHeight
        let clampedHeight = max(400, min(height, 800)) // Optional min/max cap

        let size = NSSize(width: 400, height: clampedHeight)

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.setContentSize(size)
                window.minSize = size
                window.maxSize = size
            }
        }
    }
    
    func calculateTotalTime() -> Int {
        let selectedCount = userManager.users.filter { $0.isSelected }.count
        let totalSeconds = selectedCount * timeout
        return Int(ceil(Double(totalSeconds) / 60.0)) // Rounded up to minutes
    }
}

struct EditUserView: View {
    @ObservedObject var userManager: UserManager

    var body: some View {
        VStack {
            HStack {
                Text("User Management")
                    .font(.title)
            }
            .padding()

            List {
                ForEach($userManager.users) { $user in
                    HStack {
                        TextField("Name", text: $user.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Toggle("Admin", isOn: $user.isAdmin)

                        Spacer()

                        Button(action: {
                            if let index = userManager.users.firstIndex(where: { $0.id == user.id }) {
                                deleteUser(at: IndexSet(integer: index))
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 5)
                }
                .onDelete(perform: deleteUser)
                .onMove(perform: moveUser)
            }

            Button("Add User") {
                addUser()
            }
            .padding()
        }
        .padding()
    }

    func addUser() {
        userManager.users.append(User(name: "New User", isSelected: true, isAdmin: false))
        userManager.saveUsers()
    }
 
    func deleteUser(at offsets: IndexSet) {
        userManager.users.remove(atOffsets: offsets)
        userManager.saveUsers()
    }

    func moveUser(from source: IndexSet, to destination: Int) {
        userManager.users.move(fromOffsets: source, toOffset: destination)
        userManager.saveUsers()
    }
}
