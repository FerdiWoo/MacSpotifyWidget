import Foundation
import SwiftUI
import Accelerate

/// A controller that interacts with Spotify via AppleScript,
/// allowing playback control and retrieval of now playing information.
final class SpotifyController: ObservableObject {
    /// The shared NowPlayingInfo object to update UI and state.
    @ObservedObject var nowPlayingInfo: NowPlayingInfo
    
    /// Cache for optimization
    private var lastArtworkIdentifier: String?
    private var lastUpdateTime: Date = Date()
    private var updateInterval: TimeInterval = 2.0
    private var lastTrackInfo: String = ""
    private var isUpdating = false
    
    /// Initializes the controller with a NowPlayingInfo object.
    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    /// Fetches the current now playing information from Spotify.
    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        guard !isUpdating else {
            completion(true)
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) < updateInterval {
            completion(true)
            return
        }
        
        isUpdating = true
        lastUpdateTime = now
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.performUpdate { success in
                DispatchQueue.main.async {
                    self?.isUpdating = false
                    completion(success)
                }
            }
        }
    }
    
    private func performUpdate(completion: @escaping (Bool) -> Void) {
        let isPlaying = isSpotifyPlaying()
        
        if !isPlaying {
            self.updateInterval = 5.0
            DispatchQueue.main.async {
                self.clearNowPlaying()
                completion(true)
            }
            return
        }
        
        self.updateInterval = 2.0
        
        getSpotifyInfo { info in
            DispatchQueue.main.async {
                if let info = info {
                    self.updateNowPlaying(with: info, isPlaying: true)
                } else {
                    self.clearNowPlaying()
                }
                completion(true)
            }
        }
    }
    
    // MARK: - Playback Actions
    
    /// Skips to the previous track in Spotify.
    func playPreviousTrack() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runAppleScript("""
                tell application "Spotify"
                    previous track
                end tell
            """)
        }
    }
    
    /// Skips to the next track in Spotify.
    func playNextTrack() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runAppleScript("""
                tell application "Spotify"
                    next track
                end tell
            """)
        }
    }
    
    /// Toggles play/pause in Spotify.
    func togglePlayPause() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runAppleScript("""
                tell application "Spotify"
                    playpause
                end tell
            """)
            // Reset cache
            self.lastTrackInfo = ""
            self.lastArtworkIdentifier = nil
            self.lastUpdateTime = .distantPast
        }
    }
    
    /// Seeks playback to a specific time in the current track.
    func playAtTime(to time: Double) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runAppleScript("""
                tell application "Spotify"
                    set player position to \(time)
                end tell
            """)
        }
    }
    
    // MARK: - App Status
    
    func isSpotifyPlaying() -> Bool {
        return isAppRunning("Spotify")
    }
    
    private func isAppRunning(_ appName: String) -> Bool {
        let script = """
        tell application "System Events"
            set isRunning to (name of processes) contains "\(appName)"
        end tell
        return isRunning
        """
        if let output = runAppleScript(script) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        }
        return false
    }
    
    // MARK: - AppleScript Execution
    
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)
            if error != nil {
                // Handle error silently
            }
            return result.stringValue
        }
        return nil
    }
    
    // MARK: - Now Playing Management
    
    private func clearNowPlaying() {
        nowPlayingInfo.trackName = "No Song Playing"
        nowPlayingInfo.artistName = "Unknown Artist"
        nowPlayingInfo.albumName = "Unknown Album"
        nowPlayingInfo.artworkImage = nil
        nowPlayingInfo.dominantColor = .white
        nowPlayingInfo.isPlaying = false
        
        lastTrackInfo = ""
        lastArtworkIdentifier = nil
    }
    
    private func updateNowPlaying(
        with info: (String, String, String, NSImage?, Double, Double),
        isPlaying: Bool
    ) {
        let (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds) = info
        let currentTrackIdentifier = "\(trackName)|\(artistName)|\(albumName)|\(isPlaying)"
        
        if lastTrackInfo == currentTrackIdentifier {
            // Only update time-sensitive info
            nowPlayingInfo.positionSeconds = positionSeconds
            nowPlayingInfo.durationSeconds = durationSeconds
            return
        }
        
        lastTrackInfo = currentTrackIdentifier
        
        nowPlayingInfo.trackName = trackName
        nowPlayingInfo.artistName = artistName
        nowPlayingInfo.albumName = albumName
        
        // Only update artwork and dominant color if artwork changed
        if let artworkImage = artworkImage {
            let currentArtworkIdentifier = "\(trackName)|\(albumName)|\(artworkImage.hash)"
            
            if lastArtworkIdentifier != currentArtworkIdentifier {
                nowPlayingInfo.artworkImage = artworkImage
                // Process dominant color on background queue
                DispatchQueue.global(qos: .utility).async {
                    let dominantColor = self.getDominantColor(from: artworkImage) ?? .white
                    DispatchQueue.main.async {
                        self.nowPlayingInfo.dominantColor = dominantColor
                    }
                }
                lastArtworkIdentifier = currentArtworkIdentifier
            }
        } else {
            nowPlayingInfo.dominantColor = .white
        }
        
        nowPlayingInfo.positionSeconds = positionSeconds
        nowPlayingInfo.durationSeconds = durationSeconds
        nowPlayingInfo.isPlaying = true
    }
    
    // MARK: - Spotify Info Fetching
    
    private func getSpotifyInfo(completion: @escaping ((String, String, String, NSImage?, Double, Double)?) -> Void) {
        let script = """
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set artworkURL to artwork url of current track
                set currentTime to player position
                set trackDuration to (duration of current track) / 1000
                return trackName & "||" & artistName & "||" & albumName & "||" & artworkURL & "||" & currentTime & "||" & trackDuration
            else
                return "not_playing"
            end if
        end tell
        """
        
        if let output = runAppleScript(script), output != "not_playing" {
            let components = output.components(separatedBy: "||")
            if components.count == 6 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkURLString = components[3]
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0
                
                // Fetch artwork
                let trackIdentifier = trackName + albumName
                if lastArtworkIdentifier != trackIdentifier, let artworkURL = URL(string: artworkURLString) {
                    URLSession.shared.dataTask(with: artworkURL) { data, response, error in
                        var artworkImage: NSImage? = nil
                        if let data = data {
                            artworkImage = NSImage(data: data)
                        }
                        completion((trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds))
                    }.resume()
                    return
                } else {
                    // Use existing artwork or nil
                    completion((trackName, artistName, albumName, nil, positionSeconds, durationSeconds))
                    return
                }
            }
        }
        completion(nil)
    }
    
    // MARK: - Color Extraction
    
    private func getDominantColor(from image: NSImage) -> NSColor? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let targetSize = CGSize(width: 1, height: 1)
        
        guard let resized = resizeImageWithVImage(cgImage, to: targetSize) else {
            return nil
        }
        
        guard let pixelData = resized.dataProvider?.data,
              let bytes = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        let red = CGFloat(bytes[0]) / 255.0
        let green = CGFloat(bytes[1]) / 255.0
        let blue = CGFloat(bytes[2]) / 255.0
        let alpha = CGFloat(bytes[3]) / 255.0
        
        return adjustBrightness(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    private func resizeImageWithVImage(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        var destBuffer = vImage_Buffer()
        
        guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        
        destBuffer.width = vImagePixelCount(width)
        destBuffer.height = vImagePixelCount(height)
        destBuffer.rowBytes = width * 4
        destBuffer.data = malloc(height * width * 4)
        
        let error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        
        free(sourceBuffer.data)
        
        guard error == kvImageNoError else {
            free(destBuffer.data)
            return nil
        }
        
        let context = CGContext(
            data: destBuffer.data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: destBuffer.rowBytes,
            space: format.colorSpace.takeRetainedValue(),
            bitmapInfo: format.bitmapInfo.rawValue
        )
        
        let result = context?.makeImage()
        free(destBuffer.data)
        return result
    }
    
    private func adjustBrightness(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> NSColor {
        var adjustedRed = red
        var adjustedGreen = green
        var adjustedBlue = blue
        
        let brightness = (red + green + blue) / 3.0
        
        if brightness < 0.5 {
            let scale = 0.5 / brightness
            adjustedRed = min(red * scale, 1.0)
            adjustedGreen = min(green * scale, 1.0)
            adjustedBlue = min(blue * scale, 1.0)
        }
        
        return NSColor(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue, alpha: alpha)
    }
}
