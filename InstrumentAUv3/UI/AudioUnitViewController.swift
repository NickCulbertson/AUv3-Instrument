//
//  AudioUnitViewController.swift
//  AUv3InstrumentExtension
//
//  Created by Nick Culbertson on 3/16/22.
//

import CoreAudioKit

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    var AUParam1: AUParameter?
    @IBOutlet weak var reverbSlider: UISlider!
    @IBOutlet weak var reverbLabel: UILabel!
    
    public override func viewDidLoad() {
        reverbSlider.minimumValue = 0
        reverbSlider.maximumValue = 1
        reverbSlider.value = 0.3
        reverbLabel.text = String(format: " %.2f", reverbSlider.value)
        
        super.viewDidLoad()
        
        if audioUnit == nil {
            return
        }
        connectViewToAU()
    }
    
    private var parameterObserverToken: AUParameterObserverToken?
    var observer: NSKeyValueObservation?
    var needsConnection = true
    
    private func connectViewToAU() {
        guard needsConnection, let paramTree = audioUnit?.parameterTree else { return }
        
        // Find the parameters in the parameter tree.
        AUParam1 = paramTree.value(forKey: "AUParam1") as? AUParameter
        
        // Observe major state changes like a user selecting a user preset.
        observer = audioUnit?.observe(\.allParameterValues) { object, change in
            DispatchQueue.main.async {
                //Update Preset
            }
        }
        
        // Observe value changes to parameters.
        // Update individual GUI element
        parameterObserverToken =
        paramTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            
            if ([self.AUParam1?.address].contains(address)){
                DispatchQueue.main.async {
                    self.reverbSlider.value = self.AUParam1?.value ?? 0
                    self.reverbLabel.text = String(format: " %.2f", self.AUParam1?.value ?? 0)
                }
            }
        })
        // Indicate the view and the audio unit have a connection.
        needsConnection = false
    }
    
    @IBAction func slider1ValueDidChange(_ sender: UISlider){
        if sender.tag == 1 {
            AUParam1?.value = self.reverbSlider.value
            reverbLabel.text = String(format: " %.2f", reverbSlider.value)
        }
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try InstrumentAUv3AudioUnit(componentDescription: componentDescription, options: [])
        connectViewToAU()
        return audioUnit!
    }
}
