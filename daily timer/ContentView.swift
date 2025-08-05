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
    enum AppMode: Int {
        case main = 1
        case timer = 2
        case editUsers = 3
    }
    
    // MARK: - App Storage
    @AppStorage("timerSeconds") private var timeout: Int = 90
    @AppStorage("mainWindowWidth") private var savedMainWidth: Double = 450
    @AppStorage("mainWindowHeight") private var savedMainHeight: Double = 600

    // MARK: - State
    @StateObject var userManager = UserManager()
    @State private var currentUser: User? = nil
    @State private var timeRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var showEnd: Bool = false
    @State private var mode: AppMode = .main {
        didSet {
            configureWindowForMode(mode)
        }
    }
    @State private var timer: Timer?

    var body: some View {
        FirstMouseAcceptingView {
            Group {
                switch mode {
                case .main:
                    MainView(userManager: userManager, timeout: $timeout, onStartSession: startSession, onEditUsers: {
                        mode = .editUsers
                    })
                    .onAppear {
                        if mode == .main {
                            configureWindowForMode(.main)
                        }
                    }
                    
                case .timer:
                    VStack {
                        if let currentUser = currentUser {
                            TimerView(currentUser: currentUser, timeRemaining: timeRemaining, onNextUser: nextUser)
                        } else if showEnd {
                            SessionEndView(onFinish: finishSession)
                        }
                    }
                    
                case .editUsers:
                    VStack {
                        EditUserView(userManager: userManager)
                        
                        BackButton {
                            userManager.saveUsers()
                            mode = .main
                        }
                    }
                    .padding()
                }
            }
            .padding(mode == .timer ? 0 : 24)
        }
    }

    func startSession() {
        let selectedUsers = userManager.users.filter { $0.isSelected }
        let usualUsers = selectedUsers.filter { !$0.isFinalizer }.shuffled()
        let finalizerUsers = selectedUsers.filter { $0.isFinalizer }

        guard !selectedUsers.isEmpty else { return }

        // Save current window size before switching to timer
        saveCurrentWindowSize()

        userManager.users = usualUsers + finalizerUsers
        currentUser = userManager.users.first
        timeRemaining = timeout
        mode = .timer
        startTimer()
    }
    
    private func saveCurrentWindowSize() {
        guard mode == .main else { return }
        
        if let window = NSApp.keyWindow {
            savedMainWidth = window.frame.width
            savedMainHeight = window.frame.height
        }
    }
    
    private func configureWindowForMode(_ newMode: AppMode) {
        DispatchQueue.main.async {
            guard let window = NSApp.keyWindow else { return }
            
            switch newMode {
            case .main, .editUsers:
                window.level = .normal
                window.setContentSize(NSSize(width: self.savedMainWidth, height: self.savedMainHeight))
                window.minSize = NSSize(width: 300, height: 400)
                window.maxSize = NSSize(width: 2000, height: 2000)
                
            case .timer:
                window.level = .floating
                window.setContentSize(NSSize(width: 200, height: 240))
                window.minSize = NSSize(width: 200, height: 240)
                window.maxSize = NSSize(width: 200, height: 240)
            }
        }
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
    
    func finishSession() {
        mode = .main
        showEnd = false
        currentUser = nil
        timer?.invalidate()
    }
}
