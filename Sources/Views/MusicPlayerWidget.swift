import SwiftUI
import Combine

/// Model for managing the music player widget state
class MusicPlayerWidgetModel: ObservableObject {
    static let shared = MusicPlayerWidgetModel()
    
    @Published var isDragging: Bool = false
    @Published var manualDragPosition: Double = 0
    @Published var nowPlayingInfo: NowPlayingInfo = AudioManager.shared.nowPlayingInfo
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        nowPlayingInfo.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

/// Main music player widget view
struct MusicPlayerWidget: View {
    @ObservedObject private var model = MusicPlayerWidgetModel.shared
    @State private var isHoveringSpotify = false
    @State private var cachedArtwork: NSImage?
    @State private var flipRotation: Double = 0
    
    private let albumSize: CGFloat = 80
    private let iconSize: CGFloat = 16
    private let controlButtonSize: CGFloat = 36
    private let flipDuration: Double = 0.3
    
    private var isFrontSide: Bool {
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 90 ||
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 270
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title
            HStack {
                Text("Spotify Player")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Spotify button
                Button(action: {
                    AudioManager.shared.openSpotify()
                }) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isHoveringSpotify ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringSpotify = hovering
                }
            }
            .padding(.horizontal)
            
            // Main content
            HStack(alignment: .top, spacing: 16) {
                // Album artwork with flip animation
                ZStack {
                    if let cachedArtwork = cachedArtwork {
                        Image(nsImage: cachedArtwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: albumSize, height: albumSize)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .opacity(isFrontSide ? 1 : 0)
                    } else {
                        placeholderAlbumCover
                            .opacity(isFrontSide ? 1 : 0)
                    }
                    
                    // Back side (new image)
                    if let artwork = model.nowPlayingInfo.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: albumSize, height: albumSize)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .opacity(isFrontSide ? 0 : 1)
                    }
                }
                .rotation3DEffect(.degrees(flipRotation), axis: (x: 0, y: 1, z: 0))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                .shadow(color: Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.2), radius: 16, x: 0, y: 6)
                
                // Track info and controls
                VStack(alignment: .leading, spacing: 8) {
                    // Track name
                    Text(model.nowPlayingInfo.trackName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Artist name
                    Text(model.nowPlayingInfo.artistName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    // Album name
                    Text(model.nowPlayingInfo.albumName)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Progress slider
            VStack(spacing: 4) {
                ProgressSlider(model: model)
                
                // Time labels
                HStack {
                    Text(formatDuration(model.nowPlayingInfo.positionSeconds))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(model.nowPlayingInfo.durationSeconds))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Playback controls
            HStack(spacing: 24) {
                // Previous button
                Button(action: {
                    AudioManager.shared.playPreviousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.primary)
                        .frame(width: controlButtonSize, height: controlButtonSize)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                
                // Play/Pause button
                Button(action: {
                    AudioManager.shared.togglePlayPause()
                }) {
                    Image(systemName: model.nowPlayingInfo.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: iconSize + 2))
                        .foregroundColor(.primary)
                        .frame(width: controlButtonSize + 8, height: controlButtonSize + 8)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.3),
                                                Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Circle()
                                    .strokeBorder(
                                        Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.3),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                        .shadow(color: Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.2), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                // Next button
                Button(action: {
                    AudioManager.shared.playNextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.primary)
                        .frame(width: controlButtonSize, height: controlButtonSize)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 350, height: 280)
        .background(
            ZStack {
                // Base layer with gradient
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(NSColor.windowBackgroundColor),
                                Color(NSColor.windowBackgroundColor).opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass effect overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
            }
        )
        .overlay(
            // Subtle border like Arc
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
        .shadow(color: Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.1), radius: 30, x: 0, y: 10)
        .onAppear {
            cachedArtwork = model.nowPlayingInfo.artworkImage
        }
        .onChange(of: model.nowPlayingInfo.artworkImage) { newArtwork in
            handleArtworkFlip(newArtwork: newArtwork)
        }
    }
    
    private var placeholderAlbumCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.25),
                            Color.gray.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            
            Image(systemName: "music.note")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: albumSize, height: albumSize)
    }
    
    private func handleArtworkFlip(newArtwork: NSImage?) {
        guard cachedArtwork != newArtwork else { return }
        
        withAnimation(.easeInOut(duration: flipDuration)) {
            flipRotation = 180
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
            flipRotation = 0
            cachedArtwork = newArtwork
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

/// Progress slider component
struct ProgressSlider: View {
    @ObservedObject var model: MusicPlayerWidgetModel
    
    var body: some View {
        GeometryReader { geometry in
            let effectivePosition = model.isDragging ? model.manualDragPosition : model.nowPlayingInfo.positionSeconds
            let progress = CGFloat(effectivePosition / max(model.nowPlayingInfo.durationSeconds, 1))
            
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 4)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                    )
                
                // Progress bar
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(nsColor: model.nowPlayingInfo.dominantColor),
                                Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(progress * geometry.size.width, 0), height: 4)
                
                // Draggable thumb
                Circle()
                    .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.3), radius: 4)
                    .offset(x: progress * geometry.size.width - 6)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        model.isDragging = true
                        let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                        model.manualDragPosition = Double(percentage) * model.nowPlayingInfo.durationSeconds
                    }
                    .onEnded { value in
                        let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                        let newTimeInSeconds = percentage * model.nowPlayingInfo.durationSeconds
                        
                        AudioManager.shared.playAtTime(to: newTimeInSeconds)
                        model.manualDragPosition = newTimeInSeconds
                        
                        // Check for position update
                        checkPositionUpdate(targetPosition: newTimeInSeconds, attempts: 0)
                    }
            )
        }
        .frame(height: 12)
        .padding(.horizontal)
    }
    
    private func checkPositionUpdate(targetPosition: Double, attempts: Int) {
        let maxAttempts = 10
        let checkInterval = 0.5
        
        if attempts >= maxAttempts {
            model.isDragging = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
            let currentDiff = abs(model.nowPlayingInfo.positionSeconds - targetPosition)
            
            if currentDiff < 1.0 { // Within 1 second tolerance
                model.isDragging = false
            } else {
                checkPositionUpdate(targetPosition: targetPosition, attempts: attempts + 1)
            }
        }
    }
}
