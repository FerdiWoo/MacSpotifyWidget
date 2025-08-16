import AppKit
import SwiftUI

/// AudioManager provides a unified interface for managing and controlling Spotify playback.
class AudioManager: ObservableObject {
    /// Singleton instance for global access
    static let shared = AudioManager()
    
    /// Published info about the currently playing media
    @Published var nowPlayingInfo: NowPlayingInfo = NowPlayingInfo()
    
    /// Controller for Spotify control
    lazy var spotifyController: SpotifyController = {
        SpotifyController(nowPlayingInfo: self.nowPlayingInfo)
    }()
    
    private var timer: Timer?
    
    /// Private initializer to ensure singleton pattern
    private init() {
        startMediaTimer()
    }
    
    /// Fetches and updates the current playing media information.
    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        spotifyController.getNowPlayingInfo(completion: completion)
    }
    
    /// Starts a timer to periodically refresh media information (every second).
    func startMediaTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.getNowPlayingInfo { _ in }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// Stops the periodic media info update timer.
    func stopMediaTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Playback Controls
    
    /// Skips to the previous track.
    func playPreviousTrack() {
        spotifyController.playPreviousTrack()
    }
    
    /// Skips to the next track.
    func playNextTrack() {
        spotifyController.playNextTrack()
    }
    
    /// Toggles play/pause state.
    func togglePlayPause() {
        spotifyController.togglePlayPause()
    }
    
    /// Seeks to a specific time (in seconds) in the current track.
    func playAtTime(to time: Double) {
        spotifyController.playAtTime(to: time)
    }
    
    /// Opens Spotify app.
    func openSpotify() {
        let appPath = "/Applications/Spotify.app"
        if FileManager.default.fileExists(atPath: appPath) {
            let appURL = URL(fileURLWithPath: appPath)
            NSWorkspace.shared.openApplication(at: appURL,
                                              configuration: NSWorkspace.OpenConfiguration(),
                                              completionHandler: nil)
        }
    }
}
