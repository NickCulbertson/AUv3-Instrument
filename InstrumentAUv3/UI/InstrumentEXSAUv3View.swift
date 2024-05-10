import CoreAudioKit
import SwiftUI

class AudioParameter: ObservableObject {
    @Published var value: AUValue
    var auParameter: AUParameter

    init(auParameter: AUParameter, initialValue: AUValue) {
        self.auParameter = auParameter
        self.value = initialValue
    }

    func updateValue(_ newValue: AUValue) {
        DispatchQueue.main.async {
            self.value = newValue
            self.auParameter.setValue(newValue, originator: nil)
        }
    }
}

struct InstrumentEXSAUv3View: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var audioParameter: AudioParameter
    
    func updateParameterValue(_ value: AUValue) {
        DispatchQueue.main.async {
            self.audioParameter.value = value
        }
    }

    var body: some View {
        VStack {
            ParameterSlider(text: "Reverb",
                            parameter: $audioParameter.value,
                            range: (0...1),
                            units: "Percent")
                .padding(10)
                .onChange(of: audioParameter.value) { newValue in
                                    audioParameter.updateValue(newValue)
                                }
        }
        .background(colorScheme == .dark ?
                    Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}
