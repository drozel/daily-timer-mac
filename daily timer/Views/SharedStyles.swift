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

struct LiquidGlassContainer<Content: View>: NSViewRepresentable {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    func makeNSView(context: Context) -> LiquidGlassHostView<Content> {
        LiquidGlassHostView(rootView: content, cornerRadius: cornerRadius)
    }

    func updateNSView(_ nsView: LiquidGlassHostView<Content>, context: Context) {
        nsView.update(rootView: content, cornerRadius: cornerRadius)
    }
}

final class LiquidGlassHostView<Content: View>: NSView {
    private var hostingView: NSHostingView<Content>
    private var glassView: NSView
    private var contentContainer: NSView
    private var cornerRadius: CGFloat

    init(rootView: Content, cornerRadius: CGFloat) {
        self.hostingView = NSHostingView(rootView: rootView)
        self.cornerRadius = cornerRadius
        let (glassView, contentContainer) = Self.makeGlassSurface()
        self.glassView = glassView
        self.contentContainer = contentContainer
        super.init(frame: .zero)
        setupViewTree()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(rootView: Content, cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        hostingView.rootView = rootView
        layer?.cornerRadius = cornerRadius
    }

    private func setupViewTree() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true

        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        contentContainer.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }

    private static func makeGlassSurface() -> (glass: NSView, content: NSView) {
        if let glassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glassView = glassClass.init(frame: .zero)
            glassView.wantsLayer = true
            glassView.layer?.backgroundColor = NSColor.clear.cgColor

            // NSGlassEffectView hosts content in `contentView`.
            if glassView.responds(to: NSSelectorFromString("contentView")),
               let unmanaged = glassView.perform(NSSelectorFromString("contentView")),
               let contentView = unmanaged.takeUnretainedValue() as? NSView {
                return (glassView, contentView)
            }
            return (glassView, glassView)
        }

        let fallback = NSVisualEffectView()
        fallback.material = .underWindowBackground
        fallback.blendingMode = .behindWindow
        fallback.state = .followsWindowActiveState
        fallback.isEmphasized = false
        fallback.wantsLayer = true
        fallback.layer?.backgroundColor = NSColor.clear.cgColor
        return (fallback, fallback)
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
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
