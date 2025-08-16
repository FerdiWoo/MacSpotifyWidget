import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
        VStack {
            MusicPlayerWidget()
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView())
    }
}

/// Visual effect view for macOS blur background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .sidebar
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    ContentView()
}
