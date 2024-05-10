import CoreAudioKit
import SwiftUI

#if os(iOS)
typealias HostingController = UIHostingController
#elseif os(macOS)
typealias HostingController = NSHostingController

extension NSView {
    func bringSubviewToFront(_ view: NSView) {
        // This function is a no-op for macOS
    }
}
#endif

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    var hostingController: HostingController<InstrumentEXSAUv3View>?
    var parameterObserverToken: AUParameterObserverToken?
    var observer: NSKeyValueObservation?
    var needsConnection = true
    
    var auParameter1: AUParameter?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let audioUnit = audioUnit else { return }
        setupParameterObservation()
        configureSwiftUIView(audioUnit: audioUnit)
    }

    private func setupParameterObservation() {
        guard needsConnection, let paramTree = audioUnit?.parameterTree else { return }
        auParameter1 = paramTree.value(forKey: "AUParam1") as? AUParameter
        
        observer = audioUnit?.observe(\.allParameterValues) { object, change in
                    DispatchQueue.main.async {
                        //Update Presets
                    }
                }
        
        parameterObserverToken = paramTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self, address == self.auParameter1?.address else { return }
            DispatchQueue.main.async {
                self.hostingController?.rootView.updateParameterValue(value)
            }
        })
        
        // Indicate the view and the audio unit have a connection.
        needsConnection = false
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try InstrumentAUv3AudioUnit(componentDescription: componentDescription, options: [])
        DispatchQueue.main.async {
            self.setupParameterObservation()
            self.configureSwiftUIView(audioUnit: self.audioUnit!)
        }
        return audioUnit!
    }
    
    private func configureSwiftUIView(audioUnit: AUAudioUnit) {
        guard let auParameter1 = auParameter1 else { return }
        let audioParameter = AudioParameter(auParameter: auParameter1, initialValue: auParameter1.value)
        let contentView = InstrumentEXSAUv3View(audioParameter: audioParameter)
        let hostingController = HostingController(rootView: contentView)

        if let existingHost = self.hostingController {
            existingHost.removeFromParent()
            existingHost.view.removeFromSuperview()
        }
        
        self.addChild(hostingController)
        hostingController.view.frame = self.view.bounds
        self.view.addSubview(hostingController.view)
        self.hostingController = hostingController
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}
