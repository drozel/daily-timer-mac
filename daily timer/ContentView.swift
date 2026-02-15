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
    private let minTimeout = 10
    private let maxTimeout = 600

    // MARK: - State
    @StateObject var userManager = UserManager()
    @State private var sessionUsers: [User] = []
    @State private var currentUser: User? = nil
    @State private var timeRemaining: Int = 0
    @State private var isTimerRunning: Bool = false
    @State private var showEnd: Bool = false
    @State private var appWindow: NSWindow?
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
                    ZStack {
                        VisualEffectGlassView(material: .underWindowBackground, blendingMode: .behindWindow, opacity: 0.7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.26), .white.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)

                        VStack {
                            if let currentUser = currentUser {
                                TimerView(currentUser: currentUser, timeRemaining: timeRemaining, onNextUser: nextUser)
                            } else if showEnd {
                                SessionEndView(onFinish: finishSession)
                            }
                        }
                    }
                    .background(Color.clear)
                    
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
        .onAppear {
            timeout = clampedTimeout(timeout)
            configureWindowForMode(mode)
        }
        .onChange(of: timeout) { newValue in
            let sanitized = clampedTimeout(newValue)
            if sanitized != newValue {
                timeout = sanitized
            }
        }
    }

    func startSession() {
        let plannedUsers = userManager.makeSessionUsers()
        guard !plannedUsers.isEmpty else { return }

        // Save current window size before switching to timer
        saveCurrentWindowSize()

        showEnd = false
        sessionUsers = plannedUsers
        currentUser = sessionUsers.first
        timeRemaining = clampedTimeout(timeout)
        mode = .timer
        startTimer()
    }
    
    private func saveCurrentWindowSize() {
        guard mode == .main else { return }
        
        if let window = resolveWindow() {
            savedMainWidth = window.frame.width
            savedMainHeight = window.frame.height
        }
    }
    
    private func resolveWindow() -> NSWindow? {
        if let appWindow {
            return appWindow
        }
        let resolved = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        appWindow = resolved
        return resolved
    }

    private func clampedTimeout(_ value: Int) -> Int {
        min(max(value, minTimeout), maxTimeout)
    }

    private func configureWindowForMode(_ newMode: AppMode) {
        DispatchQueue.main.async {
            guard let window = self.resolveWindow() else { return }
            
            switch newMode {
            case .main, .editUsers:
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
                window.level = .normal
                window.backgroundColor = .windowBackgroundColor
                window.isOpaque = true
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
                window.titleVisibility = .visible
                window.titlebarAppearsTransparent = false
                window.setContentSize(NSSize(width: self.savedMainWidth, height: self.savedMainHeight))
                window.minSize = NSSize(width: 300, height: 400)
                window.maxSize = NSSize(width: 2000, height: 2000)
                window.hasShadow = true
                window.isMovableByWindowBackground = false
                window.contentView?.superview?.wantsLayer = true
                window.contentView?.superview?.layer?.cornerRadius = 0
                window.contentView?.superview?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
                window.contentView?.superview?.layer?.masksToBounds = false
                
            case .timer:
                window.styleMask = [.borderless, .fullSizeContentView]
                window.level = .floating
                window.backgroundColor = .clear
                window.isOpaque = false
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
                window.hasShadow = true
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
                window.setContentSize(NSSize(width: 200, height: 240))
                window.minSize = NSSize(width: 200, height: 240)
                window.maxSize = NSSize(width: 200, height: 240)
                window.contentView?.superview?.wantsLayer = true
                window.contentView?.superview?.layer?.cornerRadius = 28
                window.contentView?.superview?.layer?.backgroundColor = NSColor.clear.cgColor
                window.contentView?.superview?.layer?.masksToBounds = true
            }
        }
    }

    func startTimer() {
        timer?.invalidate()
        timeRemaining = clampedTimeout(timeout)
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
        
        if let currentIndex = sessionUsers.firstIndex(where: { $0.id == currentUser?.id }) {
            if currentIndex + 1 < sessionUsers.count {
                currentUser = sessionUsers[currentIndex + 1]
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
        sessionUsers = []
        timer?.invalidate()
    }
}
