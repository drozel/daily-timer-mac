import SwiftUI

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        AnimatedButton(action: action) {
            HStack {
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.blue, lineWidth: 1.5)
            )
        }
    }
}

struct ContentView: View {
    // MARK: - Types
    private enum AppMode: Int {
        case main = 1
        case timer = 2
        case editUsers = 3
    }
    
    // MARK: - Constants
    private enum WindowSize {
        static let timer = NSSize(width: 200, height: 240)
        static let mainDefault = NSSize(width: 450, height: 600)
        static let mainMinimum = NSSize(width: 300, height: 200)
        static let mainMaximum = NSSize(width: 10000, height: 10000)
    }
    
    // MARK: - App Storage
    @AppStorage("timerSeconds") private var timeout: Int = 90
    @AppStorage("mainWindowWidth") private var savedWindowWidth: Double = WindowSize.mainDefault.width
    @AppStorage("mainWindowHeight") private var savedWindowHeight: Double = WindowSize.mainDefault.height

    // MARK: - State
    @StateObject var userManager = UserManager()
    @State private var currentUser: User? = nil
    @State private var timeRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var showEnd: Bool = false
    @State private var mode: AppMode = .main
    @State private var timer: Timer?

    var body: some View {
        FirstMouseAcceptingView {
            VStack {
                switch mode {
                case .main:
                    MainView(userManager: userManager, timeout: $timeout, onStartSession: startSession, onEditUsers: {
                        mode = .editUsers
                    })
                    .onAppear {
                        restoreMainWindowSize()
                    }
                case .timer:
                    if let currentUser = currentUser {
                        TimerView(currentUser: currentUser, timeRemaining: timeRemaining, onNextUser: nextUser)
                    } else if showEnd {
                        SessionEndView()
                    }
                case .editUsers:
                    VStack {
                        EditUserView(userManager: userManager)
                        
                        BackButton {
                            userManager.saveUsers()
                            mode = .main
                            restoreMainWindowSize()
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    func startSession() {
        let selectedUsers = userManager.users.filter { $0.isSelected }
        let usualUsers = selectedUsers.filter { !$0.isFinalizer }.shuffled()
        let finalizerUsers = selectedUsers.filter { $0.isFinalizer }

        guard !selectedUsers.isEmpty else { return }

        // Save current main window size before switching to timer
        saveMainWindowSize()

        userManager.users = usualUsers + finalizerUsers
        currentUser = userManager.users.first
        timeRemaining = timeout
        resizeTimerWindow()
        mode = .timer
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
