
import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit
import AudioKit

public class InstrumentAUv3AudioUnit: AUAudioUnit {

    var engine: AVAudioEngine!    // each unit needs its own avaudioEngine
    var conductor: Conductor!
    var paramTree = AUParameterTree()
    private var _currentPreset: AUAudioUnitPreset?
    private let appStateKey = "appStatePreset"
    private let lastLoadedPresetKey = "lastLoadedPreset"

    var AUParam1 = AUParameterTree.createParameter(withIdentifier: "AUParam1",
                                                          name: "Reverb",
                                                          address: 0,
                                                          min: 0.0,
                                                          max: 1.0,
                                                          unit: .generic,
                                                          unitName: nil,
                                                          flags: [.flag_IsReadable,
                                                                  .flag_IsWritable,
                                                                  .flag_CanRamp],
                                                          valueStrings: nil,
                                                          dependentParameters: nil)

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        Settings.sampleRate = AVAudioSession.sharedInstance().sampleRate
        Settings.disableAVAudioSessionCategoryManagement = true
        conductor = Conductor()
        conductor.start()
        engine = conductor.engine.avEngine
        
        do {
            //this is where the audio unit really starts firing up with the data it needs
            try engine.enableManualRenderingMode(.offline, format: Settings.audioFormat, maximumFrameCount: 4096)
            try super.init(componentDescription: componentDescription, options: options)
            try setOutputBusArrays()
        } catch {
            Log("Could not init audio unit")
            throw error
        }

        setupParamTree()
        setupParamCallbacks()
        setInternalRenderingBlock() // set internal rendering block to actually handle the audio buffers

        // Log component description values
        log(componentDescription)
    }

    public override var factoryPresets: [AUAudioUnitPreset] {
        return [
            AUAudioUnitPreset(number: 0, name: "No Reverb"),
            AUAudioUnitPreset(number: 1, name: "Full Reverb")
        ]
    }

    /// The currently selected preset.
    public override var currentPreset: AUAudioUnitPreset? {
        get { return _currentPreset }
        set {
            // If the newValue is nil, return.
            guard let preset = newValue else {
                _currentPreset = nil
                return
            }
            
            // Factory presets need to always have a number >= 0.
            if preset.number >= 0 {
                _currentPreset = preset
                if preset.number == 0 {
                    //No Reverb
                    AUParam1.value = 0
                } else if preset.number == 1 {
                    //Full Reverb
                    AUParam1.value = 1
                }
            }
            // User presets are always negative.
            else {
                // Attempt to restore the archived state for this user preset.
                do {
                    fullStateForDocument = try presetState(for: preset)
                    // Set the currentPreset after successfully restoring the state.
                    _currentPreset = preset
                } catch {
                    print("Unable to restore set for preset \(preset.name)")
                }
            }
        }
    }

    override public var supportsUserPresets: Bool {
        return false
    }

    public func setupParamTree() {
        // Create the parameter tree.
        parameterTree = AUParameterTree.createTree(withChildren: [AUParam1])
    }
    
    public func setupParamCallbacks() {
        //This changes the values of the conductor
        parameterTree?.implementorValueObserver = { param, value in

            if param.identifier == "AUParam1" {
                self.conductor.verb.dryWetMix=value
            }
        }
    }
    

    private func handleEvents(eventsList: AURenderEvent?, timestamp: UnsafePointer<AudioTimeStamp>) {
        var nextEvent = eventsList
        while nextEvent != nil {
            if nextEvent!.head.eventType == .MIDI {
                handleMIDI(midiEvent: nextEvent!.MIDI, timestamp: timestamp)
            } else if (nextEvent!.head.eventType == .parameter ||  nextEvent!.head.eventType == .parameterRamp) {
                handleParameter(parameterEvent: nextEvent!.parameter, timestamp: timestamp)
            }
            nextEvent = nextEvent!.head.next?.pointee
        }
    }

    private func setInternalRenderingBlock() {
        self._internalRenderBlock = { [weak self] (actionFlags, timestamp, frameCount, outputBusNumber,
            outputData, renderEvent, pullInputBlock) in
            guard let self = self else { return 1 } //error code?
            if let eventList = renderEvent?.pointee {
                self.handleEvents(eventsList: eventList, timestamp: timestamp)
            }
            //            self.handleMusicalContext()
            //            self.handleTransportState()

            // this is the line that actually produces sound using the buffers, keep it at the end
            _ = self.engine.manualRenderingBlock(frameCount, outputData, nil)
            return noErr
        }
    }

    private func log(_ acd: AudioComponentDescription) {
        let info = ProcessInfo.processInfo
        print("\nProcess Name: \(info.processName) PID: \(info.processIdentifier)\n")

        let message = """
        Overdrive Synth (
                  type: \(acd.componentType.stringValue)
               subtype: \(acd.componentSubType.stringValue)
          manufacturer: \(acd.componentManufacturer.stringValue)
                 flags: \(String(format: "%#010x", acd.componentFlags))
        )
        """
        print(message)
    }

    override public func allocateRenderResources() throws {
        do {
            try engine.enableManualRenderingMode(.offline, format: outputBus.format, maximumFrameCount: 4096)
            Settings.disableAVAudioSessionCategoryManagement = true
            let sessionSize = Settings.session.sampleRate * Settings.session.ioBufferDuration
            if let length = Settings.BufferLength.init(rawValue: Int(sessionSize.rounded())) {
                Settings.bufferLength = length
            }
            Settings.sampleRate = outputBus.format.sampleRate
            conductor.start()
            try super.allocateRenderResources()
        } catch {
            return
        }
        self.mcb = self.musicalContextBlock
        self.tsb = self.transportStateBlock
        self.moeb = self.midiOutputEventBlock

    }

    override public func deallocateRenderResources() {
        conductor.stop()
        engine.stop()
        super.deallocateRenderResources()
        self.mcb = nil
        self.tsb = nil
        self.moeb = nil
    }

    private func handleParameter(parameterEvent event: AUParameterEvent, timestamp: UnsafePointer<AudioTimeStamp>) {
            parameterTree?.parameter(withAddress: event.parameterAddress)?.value = event.value
    }

    private func handleMIDI(midiEvent event: AUMIDIEvent, timestamp: UnsafePointer<AudioTimeStamp>) {
        let diff = Float64(event.eventSampleTime) - timestamp.pointee.mSampleTime
        let offset = MIDITimeStamp(UInt32(max(0, diff)))
        let midiEvent = MIDIEvent(data: [event.data.0, event.data.1, event.data.2])
        guard let statusType = midiEvent.status?.type else { return }
        if statusType == .noteOn {
            if midiEvent.data[2] == 0 {
                receivedMIDINoteOff(noteNumber: event.data.1, channel: midiEvent.channel ?? 0, offset: offset)
            } else {
                receivedMIDINoteOn(noteNumber: event.data.1, velocity: event.data.2,
                                   channel: midiEvent.channel ?? 0, offset: offset)
            }
        } else if statusType == .noteOff {
            receivedMIDINoteOff(noteNumber: event.data.1, channel: midiEvent.channel ?? 0, offset: offset)
        } else if statusType == .controllerChange {
            if event.data.1 == 1 {
                conductor.instrument.midiCC(event.data.1, value: event.data.2, channel: midiEvent.channel ?? 0)
            }
        } else if statusType == .pitchWheel, let pitchAmount = midiEvent.pitchbendAmount, let channel = midiEvent.channel {
            conductor.instrument.setPitchbend(amount: pitchAmount, channel: channel)
        } else {
            Log("non midi note event")
        }
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel,
                            offset: MIDITimeStamp) {
        conductor.instrument.play(noteNumber: noteNumber, velocity: velocity, channel: channel)

    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, channel: MIDIChannel, offset: MIDITimeStamp) {
        conductor.instrument.stop(noteNumber: noteNumber, channel: channel)
    }
    
    // Boolean indicating that this AU can process the input audio in-place
    // in the input buffer, without requiring a separate output buffer.
    public override var canProcessInPlace: Bool {
        return true
    }

    var mcb: AUHostMusicalContextBlock?
    var tsb: AUHostTransportStateBlock?
    var moeb: AUMIDIOutputEventBlock?

    // Parameter tree stuff (for automation + control)
    open var _parameterTree: AUParameterTree!
    override open var parameterTree: AUParameterTree? {
        get { return self._parameterTree }
        set { _parameterTree = newValue }
    }

    // Internal Render block stuff
    open var _internalRenderBlock: AUInternalRenderBlock!
    override open var internalRenderBlock: AUInternalRenderBlock {
        return self._internalRenderBlock
    }

    // Default OutputBusArray stuff you will need
    var outputBus: AUAudioUnitBus!
    open var _outputBusArray: AUAudioUnitBusArray!
    override open var outputBusses: AUAudioUnitBusArray {
        return self._outputBusArray
    }
    
    open func setOutputBusArrays() throws {
        outputBus = try AUAudioUnitBus(format: Settings.audioFormat)
        self._outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus])
    }

    override open func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        var index = 0
        var returnValue = IndexSet()

        for configuration in availableViewConfigurations {
            print("width", configuration.width)
            print("height", configuration.height)
            print("has controller", configuration.hostHasController)
            print("")
            returnValue.insert(index)
            index += 1
        }
        return returnValue // Support everything
    }
}

fileprivate extension AUAudioUnitPreset {
    convenience init(number: Int, name: String) {
        self.init()
        self.number = number
        self.name = name
    }
}

extension FourCharCode {
    var stringValue: String {
        let value = CFSwapInt32BigToHost(self)
        let bytes = [0, 8, 16, 24].map { UInt8(value >> $0 & 0x000000FF) }
        guard let result = String(bytes: bytes, encoding: .macOSRoman) else {
            return "fail"
        }
        return result
    }
}
