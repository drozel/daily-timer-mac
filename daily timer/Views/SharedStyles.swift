import SwiftUI

// A button with a modern, animated design
struct AnimatedButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    let isEnabled: Bool
    
    init(action: @escaping () -> Void, isEnabled: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.isEnabled = isEnabled
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
        }
        .buttonStyle(AnimatedButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
    }
}

struct AnimatedButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity((configuration.isPressed ? 0.8 : 1.0) * (isEnabled ? 1.0 : 0.6))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct VisualEffectGlassView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let opacity: CGFloat

    init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        opacity: CGFloat = 0.72
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.opacity = opacity
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        view.isEmphasized = false
        view.alphaValue = opacity
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .followsWindowActiveState
        nsView.isEmphasized = false
        nsView.alphaValue = opacity
        nsView.layer?.backgroundColor = NSColor.clear.cgColor
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
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
