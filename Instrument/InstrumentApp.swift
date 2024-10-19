import SwiftUI
import AVFoundation
import AudioKit

@main
struct InstrumentApp: App {
    
    init() {
#if os(iOS)
        do {
            // Settings.sampleRate default is 44_100
            if #available(iOS 18.0, *) {
                if !ProcessInfo.processInfo.isMacCatalystApp && !ProcessInfo.processInfo.isiOSAppOnMac {
                    // Set samplerRate for iOS 18 and newer (not on macOS)
                    Settings.sampleRate = 48_000
                }
            }
            if #available(macOS 15.0, *) {
                // Set samplerRate for macOS 15 and newer
                Settings.sampleRate = 48_000
            }
            
            Settings.bufferLength = .medium
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            options: [.mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print(err)
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            InstrumentEXSView()
        }
    }
}
