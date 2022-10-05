import Foundation
import SwiftUI
import Keyboard
import Tonic
import AudioKit
import AVFoundation
struct SwiftUIKeyboard: View {
    var firstOctave: Int
    var octaveCount: Int
    var noteOn: (Pitch, CGPoint) -> Void = { _, _ in }
    var noteOff: (Pitch)->Void
    var body: some View {
        Keyboard(layout: .piano(pitchRange: Pitch(intValue: firstOctave * 12 + 24)...Pitch(intValue: firstOctave * 12 + octaveCount * 12 + 24)),
                 noteOn: noteOn, noteOff: noteOff){ pitch, isActivated in
            KeyboardKey(pitch: pitch,
                        isActivated: isActivated,
                        text: "",
                        pressedColor: Color.pink,
                        flatTop: true)
        }.cornerRadius(5)
    }
}
