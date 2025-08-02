import SwiftUI

// A button with a modern, animated design
struct AnimatedButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    let isEnabled: Bool
    
    @GestureState private var isPressed = false
    
    init(action: @escaping () -> Void, isEnabled: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.isEnabled = isEnabled
        self.content = content
    }
    
    var body: some View {
        content()
            .contentShape(Rectangle()) // Ensure the entire area is clickable
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity((isPressed ? 0.8 : 1.0) * (isEnabled ? 1.0 : 0.6))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        if isEnabled {
                            state = true
                        }
                    }
                    .onEnded { _ in
                        if isEnabled {
                            action()
                        }
                    }
            )
    }
}

// A wrapper view that accepts first mouse clicks on macOS
struct FirstMouseAcceptingView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSHostingView<Content> {
        let hostingView = FirstMouseAcceptingHostingView(rootView: content)
        return hostingView
    }
    
    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

// Custom NSHostingView that accepts first mouse
class FirstMouseAcceptingHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}