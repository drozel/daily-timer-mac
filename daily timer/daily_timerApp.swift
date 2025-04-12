import SwiftUI

@main
struct DailyTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    makeWindowAlwaysOnTop()
                    resizeWindow(to: NSSize(width: 400, height: 500))
                }
        }
    }

    func makeWindowAlwaysOnTop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.mainWindow {
                window.level = .floating
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

}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
