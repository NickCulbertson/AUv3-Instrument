import AudioKit
import AudioKitUI
import AVFoundation
import SwiftUI

class InstrumentEXSConductor: ObservableObject, KeyboardDelegate {

    @Published var conductor = Conductor()
    let midi = MIDI()

    func noteOn(note: MIDINoteNumber) {
        conductor.instrument.play(noteNumber: note, velocity: 90, channel: 0)
    }

    func noteOff(note: MIDINoteNumber) {
        conductor.instrument.stop(noteNumber: note, channel: 0)
    }

    init() {
        midi.addListener(self)
    }

    func start() {
        // Load EXS file (you can also load SoundFonts and WAV files too using the AppleSampler Class)
        do {
            if let fileURL = Bundle.main.url(forResource: "Sounds/SquareInstrument", withExtension: "exs") {
                try conductor.instrument.loadInstrument(url: fileURL)
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load instrument")
        }
        do {
            try conductor.engine.start()
        } catch {
            Log("AudioKit did not start!")
        }
        midi.openInput()
    }

    func stop() {
        conductor.engine.stop()
        midi.closeAllInputs()
    }
}

struct InstrumentEXSView: View {
    @StateObject var instrumentEXSConductor = InstrumentEXSConductor()
    @Environment(\.scenePhase) var scenePhase
    var backgroundMode = true // This variable controls the background audio state. Your users might want to disable it to save on battery usage.

    var body: some View {
        ParameterSlider(text: "Reverb",
                        parameter: self.$instrumentEXSConductor.conductor.verb.dryWetMix,
                        range:(0...1),
                        units: "Percent").padding(10)
        KeyboardControl(firstOctave: 2,
                        octaveCount: 2,
                        polyphonicMode: true,
                        delegate: instrumentEXSConductor)
        .onAppear {
            if(!self.instrumentEXSConductor.conductor.engine.avEngine.isRunning) {
                Log("Engine Starting")
                self.instrumentEXSConductor.start()
            }
        }
        // Background Engine Start & Stop
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Log("Active")
                if(!self.instrumentEXSConductor.conductor.engine.avEngine.isRunning) {
                    Log("Engine Starting")
                    self.instrumentEXSConductor.start()
                }
            } else if newPhase == .background {
                Log("Background")
                if(!backgroundMode){
                    Log("Engine Stopped")
                    self.instrumentEXSConductor.stop()
                }
            }
        }
        // Phone Call Start & Stop
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { event in
            guard let info = event.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                      return
                  }
            if type == .began {
                // Interruption began, take appropriate actions (save state, update user interface)
                self.instrumentEXSConductor.stop()
            }
            else if type == .ended {
                guard let optionsValue =
                        info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                            return
                        }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                    if(self.instrumentEXSConductor.conductor.engine.avEngine.isRunning) {
                        print("Engine Already Running")
                    } else {
                        let deadlineTime = DispatchTime.now() + .milliseconds(1000)
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            self.instrumentEXSConductor.start()
                        }
                    }
                }
            }
        }
    }
}

struct InstrumentEXSView_Previews: PreviewProvider {
    static var previews: some View {
        InstrumentEXSView()
    }
}

extension InstrumentEXSConductor: MIDIListener {
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        conductor.instrument.play(noteNumber: noteNumber, velocity: velocity, channel: channel)
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        conductor.instrument.stop(noteNumber: noteNumber, channel: channel)
    }

    func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        conductor.instrument.midiCC(1, value: value, channel: channel)
    }

    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        conductor.instrument.setPitchbend(amount: pitchWheelValue, channel: channel)
    }

    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        
    }

    func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
    
    }

    func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        
    }

    func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        
    }

    func receivedMIDISetupChange() {
        
    }

    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {
        
    }

    func receivedMIDINotification(notification: MIDINotification) {
        
    }
}
