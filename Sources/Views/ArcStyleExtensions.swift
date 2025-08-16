import SwiftUI

// MARK: - Arc-style Button Modifiers
struct ArcButtonStyle: ButtonStyle {
    let isHovered: Bool
    let baseColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Hover Effect View Modifier
struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat
    let shadowRadius: CGFloat
    
    init(scale: CGFloat = 1.02, shadowRadius: CGFloat = 15) {
        self.scale = scale
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.1),
                radius: isHovered ? shadowRadius : 10,
                x: 0,
                y: isHovered ? 8 : 5
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Glass Morphism Background
struct GlassMorphism: ViewModifier {
    let cornerRadius: CGFloat
    let material: NSVisualEffectView.Material
    
    init(cornerRadius: CGFloat = 20, material: NSVisualEffectView.Material = .hudWindow) {
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBackground(material: material)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradient: View {
    @State private var animateGradient = false
    let colors: [Color]
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func arcHoverEffect(scale: CGFloat = 1.02, shadowRadius: CGFloat = 15) -> some View {
        modifier(HoverEffect(scale: scale, shadowRadius: shadowRadius))
    }
    
    func glassMorphism(cornerRadius: CGFloat = 20, material: NSVisualEffectView.Material = .hudWindow) -> some View {
        modifier(GlassMorphism(cornerRadius: cornerRadius, material: material))
    }
    
    func arcCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Custom Colors for Arc Style
extension Color {
    static let arcBackground = Color(NSColor.controlBackgroundColor)
    static let arcSecondaryBackground = Color(NSColor.windowBackgroundColor)
    static let arcBorder = Color.white.opacity(0.1)
    static let arcShadow = Color.black.opacity(0.1)
    
    static func arcAccent(from baseColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                baseColor.opacity(0.8),
                baseColor.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
