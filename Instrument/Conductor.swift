import AudioKit
import AVFoundation

class Conductor: ObservableObject {

    //The AudioKit engine is AudioEngine() in v5 and Engine() in v6
    let engine = Engine()
    var instrument = MIDISampler(name: "Instrument 1")
    @Published var verb: Reverb

    init() {
        verb = Reverb(instrument)
        verb.dryWetMix = 0.3
        engine.output = verb
    }

    func start() {
        // Load EXS file (you can also load SoundFonts and WAV files too using the AppleSampler Class)
        do {
            if let fileURL = Bundle.main.url(forResource: "Sounds/SquareInstrument", withExtension: "exs") {
                try instrument.loadInstrument(url: fileURL)
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load instrument")
        }
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start!")
        }
    }

    func stop() {
        engine.stop()
    }
}
