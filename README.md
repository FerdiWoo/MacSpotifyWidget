# Spotify Player Widget for macOS

(Uncompleted) A beautiful, native macOS widget for controlling Spotify playback with a clean and modern interface.

![Spotify Player Widget](screenshot.png)

## Features

- 🎵 **Real-time playback control** - Play, pause, skip tracks
- 🎨 **Dynamic album artwork** with smooth flip animations
- 🎯 **Progress slider** - Seek to any position in the track
- 🌈 **Adaptive colors** - UI adapts to album artwork colors
- ⚡ **Lightweight** - Uses AppleScript for Spotify control
- 🖥️ **Native macOS** - Built with SwiftUI for seamless integration

## Requirements

- macOS 13.0 (Ventura) or later
- Spotify desktop app installed
- Swift 5.9 or later

## Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/SpotifyPlayerWidget.git
cd SpotifyPlayerWidget
```

2. Build using Swift Package Manager:
```bash
swift build -c release
```

3. Run the app:
```bash
./.build/release/SpotifyPlayerWidget
```

### Option 2: Xcode

1. Open the project in Xcode:
```bash
open Package.swift
```

2. Select your target device and click Run (⌘R)

## Usage

1. Launch the Spotify Player Widget
2. Start playing music in Spotify
3. The widget will automatically detect and display the current track
4. Use the controls to:
   - Skip to previous/next track
   - Play/pause playback
   - Drag the progress slider to seek
   - Click the Spotify icon to open the Spotify app

## Architecture

The project is organized into a clean, modular structure:

```
SpotifyPlayerWidget/
├── Sources/
│   ├── App/              # Main app and window setup
│   ├── Controllers/      # Audio management and Spotify control
│   ├── Models/          # Data models (NowPlayingInfo)
│   └── Views/           # SwiftUI views and UI components
```

### Key Components

- **SpotifyController**: Manages AppleScript communication with Spotify
- **AudioManager**: Singleton that coordinates playback and updates
- **MusicPlayerWidget**: Main UI component with album art and controls
- **NowPlayingInfo**: Observable model for current track information

## How It Works

The widget uses AppleScript to communicate with the Spotify desktop application. It:
1. Polls Spotify every second for track information
2. Downloads album artwork from Spotify's servers
3. Extracts dominant colors from artwork for UI theming
4. Sends playback commands through AppleScript

## Customization

You can customize the widget by modifying:
- `albumSize`: Change the album artwork size
- `controlButtonSize`: Adjust control button dimensions
- Update interval in `AudioManager.swift`
- UI colors and styling in `MusicPlayerWidget.swift`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available under the MIT License. See the LICENSE file for more info.

## Acknowledgments

- Inspired by ComfyNotch's music player implementation
- Built with SwiftUI and the Accelerate framework for image processing

## Troubleshooting

### Widget doesn't show track info
- Make sure Spotify desktop app is running
- Grant necessary AppleScript permissions when prompted

### Controls not working
- Ensure the app has Accessibility permissions in System Preferences
- Try restarting both the widget and Spotify

### Performance issues
- The widget uses minimal resources, but you can adjust the update interval in `AudioManager.swift`

## Support

For issues and questions, please open an issue on GitHub.
