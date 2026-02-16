import SwiftUI

struct ContentView: View {
    // MARK: - Types
    enum AppMode: Int {
        case main = 1
        case timer = 2
    }
    
    // MARK: - App Storage
    @AppStorage("timerSeconds") private var timeout: Int = 90
    private let minTimeout = 10
    private let maxTimeout = 600
    private let preferredMainWidth: Double = 420
    private let preferredMainHeight: Double = 540
    private let mainMinimumWidth: Double = 340
    private let mainMinimumHeight: Double = 430

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
                    MainView(userManager: userManager, timeout: $timeout, onStartSession: startSession)
                    
                case .timer:
                    LiquidGlassContainer(cornerRadius: 28) {
                        VStack {
                            if let currentUser = currentUser {
                                TimerView(currentUser: currentUser, timeRemaining: timeRemaining, onNextUser: nextUser)
                            } else if showEnd {
                                SessionEndView(onFinish: finishSession)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onChange(of: userManager.users.count) { _ in
            if mode == .main {
                configureWindowForMode(.main)
            }
        }
    }

    func startSession() {
        let plannedUsers = userManager.makeSessionUsers()
        guard !plannedUsers.isEmpty else { return }

        showEnd = false
        sessionUsers = plannedUsers
        currentUser = sessionUsers.first
        timeRemaining = clampedTimeout(timeout)
        mode = .timer
        startTimer()
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
    
    private func clampedMainWindowSize(userCount: Int) -> NSSize {
        let minimum = NSSize(width: mainMinimumWidth, height: mainMinimumHeight)

        // Approximate the main view height required to show all users without scroll.
        let rowHeight = 40.0
        let rowSpacing = 5.0
        let baseHeightWithoutRows = 380.0
        let totalRowsHeight = Double(userCount) * rowHeight + Double(max(userCount - 1, 0)) * rowSpacing
        let desiredHeight = max(preferredMainHeight, baseHeightWithoutRows + totalRowsHeight)

        guard let visibleFrame = (resolveWindow()?.screen ?? NSScreen.main)?.visibleFrame else {
            return NSSize(
                width: max(preferredMainWidth, minimum.width),
                height: max(desiredHeight, minimum.height)
            )
        }

        let maxWidth = max(minimum.width, visibleFrame.width - 40)
        let maxHeight = max(minimum.height, visibleFrame.height - 40)
        return NSSize(
            width: min(max(preferredMainWidth, minimum.width), maxWidth),
            height: min(max(desiredHeight, minimum.height), maxHeight)
        )
    }

    private func configureWindowForMode(_ newMode: AppMode) {
        DispatchQueue.main.async {
            guard let window = self.resolveWindow() else { return }
            
            switch newMode {
            case .main:
                let mainSize = self.clampedMainWindowSize(userCount: self.userManager.users.count)
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
                window.level = .normal
                window.backgroundColor = .windowBackgroundColor
                window.isOpaque = true
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
                window.titleVisibility = .visible
                window.titlebarAppearsTransparent = false
                window.setContentSize(mainSize)
                window.minSize = NSSize(width: mainMinimumWidth, height: mainMinimumHeight)
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
        timer?.invalidate()
        NSApp.terminate(nil)
    }
}
