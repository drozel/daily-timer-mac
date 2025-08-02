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
    @AppStorage("mainWindowWidth") private var savedWindowWidth: Double = 450
    @AppStorage("mainWindowHeight") private var savedWindowHeight: Double = 600

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
                MainView(userManager: userManager, timeout: $timeout, onStartSession: startSession, onEditUsers: {
                    mode = 3
                })
                .onAppear {
                    restoreMainWindowSize()
                }
            }
            else if mode == 2 {
                if let currentUser = currentUser {
                    VStack(spacing: 16) {
                        // User name with refined typography
                        Text(currentUser.name)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        // Timer display with modern styling
                        ZStack {
                            if timeRemaining == 0 {
                                // Time's up indicator with fire emoji in circle
                                Circle()
                                    .fill(.red.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("🔥")
                                            .font(.system(size: 32))
                                            .scaleEffect(1.0)
                                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: timeRemaining)
                                    )
                            } else {
                                // Timer with circular progress background
                                Circle()
                                    .fill(.gray.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("\(timeRemaining)")
                                            .font(.system(size: 28, weight: .medium, design: .rounded))
                                            .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                                            .monospacedDigit()
                                    )
                            }
                        }
                        
                        // Next button with modern Apple styling
                        Button(action: nextUser) {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 16, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.blue)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: timeRemaining)
                    }
                    .padding(20)
                } else if showEnd {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                            .symbolEffect(.bounce, value: showEnd)
                        
                        Text("Done!")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Button("Finish") {
                            exit(0)
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.green)
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                }
            }

            else if mode == 3 {
                EditUserView(userManager: userManager)
                Button("Back") {
                    userManager.saveUsers()
                    mode = 1
                    restoreMainWindowSize()
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

        // Save current main window size before switching to timer
        saveMainWindowSize()
        
        userManager.users = nonAdminUsers + adminUsers
        currentUser = userManager.users.first
        timeRemaining = timeout
        resizeTimerWindow()
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
    
    func resizeTimerWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.setContentSize(NSSize(width: 200, height: 240))
                window.minSize = NSSize(width: 200, height: 240)
                window.maxSize = NSSize(width: 200, height: 240)
                // Make timer window float on top
                window.level = .floating
            }
        }
    }
    
    func saveMainWindowSize() {
        if let window = NSApplication.shared.windows.first {
            let currentSize = window.frame.size
            savedWindowWidth = currentSize.width
            savedWindowHeight = currentSize.height
        }
    }
    
    func restoreMainWindowSize() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                // Remove size constraints
                window.minSize = NSSize(width: 300, height: 200)
                window.maxSize = NSSize(width: 10000, height: 10000)
                
                // Reset window level to normal (not floating on top)
                window.level = .normal
                
                // Restore saved size
                let restoredSize = NSSize(width: self.savedWindowWidth, height: self.savedWindowHeight)
                window.setContentSize(restoredSize)
            }
        }
    }
}

struct EditUserView: View {
    @ObservedObject var userManager: UserManager
    @FocusState private var focusedField: UUID?

    var body: some View {
        VStack {
            HStack {
                Text("User Management")
                    .font(.title)
            }
            .padding()

            ScrollViewReader { proxy in
                List {
                    ForEach($userManager.users) { $user in
                        HStack {
                            TextField("Name", text: $user.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: user.id)
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
                        .id(user.id)
                    }
                    .onDelete(perform: deleteUser)
                    .onMove(perform: moveUser)
                }

                Button("Add User") {
                    addUser(scrollProxy: proxy)
                }
                .padding()
            }
            .padding()
        }
        .padding()
    }

    func addUser(scrollProxy: ScrollViewProxy) {
        let newUser = User(name: "New User", isSelected: true, isAdmin: false)
        userManager.users.append(newUser)
        userManager.saveUsers()
        
        // Focus on the newly added user's text field and scroll to it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newUser.id
            withAnimation(.easeInOut(duration: 0.5)) {
                scrollProxy.scrollTo(newUser.id, anchor: UnitPoint.bottom)
            }
        }
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

struct MainView: View {
    @ObservedObject var userManager: UserManager
    @Binding var timeout: Int
    let onStartSession: () -> Void
    let onEditUsers: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HeaderView()
            UserListView(userManager: userManager)
            TimerSettingsView(timeout: $timeout)
            SessionInfoView(userManager: userManager, timeout: timeout)
            ActionButtonsView(
                userManager: userManager,
                onStartSession: onStartSession,
                onEditUsers: onEditUsers
            )
        }
        .padding(24)
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Daily Standup Timer")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Select your team and start timing")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
}

struct UserListView: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Teammates")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($userManager.users) { $user in
                        UserRowView(user: $user, userManager: userManager)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct UserRowView: View {
    @Binding var user: User
    let userManager: UserManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                user.isSelected.toggle()
                userManager.saveUsers()
            }) {
                Image(systemName: user.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(user.isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(user.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if user.isAdmin {
                Text("ADMIN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.orange.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(user.isSelected ? .blue.opacity(0.05) : .gray.opacity(0.1))
        )
    }
}

struct TimerSettingsView: View {
    @Binding var timeout: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Timer Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Text("Duration:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("90", value: $timeout, formatter: NumberFormatter())
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Text("seconds")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.1))
            )
        }
    }
}

struct SessionInfoView: View {
    let userManager: UserManager
    let timeout: Int
    
    private func calculateTotalTime() -> Int {
        let selectedCount = userManager.users.filter { $0.isSelected }.count
        let totalSeconds = selectedCount * timeout
        return Int(ceil(Double(totalSeconds) / 60.0))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 16)
                Text("Teammates today: \(userManager.users.filter { $0.isSelected }.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .frame(width: 16)
                Text("Total time: \(calculateTotalTime()) minutes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        )
    }
}

struct ActionButtonsView: View {
    let userManager: UserManager
    let onStartSession: () -> Void
    let onEditUsers: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Edit Users") {
                onEditUsers()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.blue, lineWidth: 1.5)
            )
            .buttonStyle(PlainButtonStyle())
            
            Button("START") {
                onStartSession()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.blue)
            )
            .buttonStyle(PlainButtonStyle())
            .disabled(userManager.users.filter { $0.isSelected }.isEmpty)
            .opacity(userManager.users.filter { $0.isSelected }.isEmpty ? 0.6 : 1.0)
        }
        .padding(.bottom, 8)
    }
}
