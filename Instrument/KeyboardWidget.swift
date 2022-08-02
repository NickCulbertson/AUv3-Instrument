// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
import AudioKit
import SwiftUI
import AudioKitUI

public struct KeyboardWidgetClass: ViewRepresentable {
    var firstOctave: Int
    var octaveCount: Int
    var polyphonicMode: Bool

    public typealias UIViewType = KeyboardViewClass
    public var delegate: KeyboardDelegate?

    #if os(macOS)
    public func makeNSView(context: Context) -> KeyboardViewClass {
        let view = KeyboardViewClass(width: 400, height: 100)
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        view.polyphonicMode = polyphonicMode
        return view
    }
    public func updateNSView(_ nsView: KeyboardViewClass, context: Context) {
        nsView.firstOctave = firstOctave
        nsView.octaveCount = octaveCount
        nsView.polyphonicMode = polyphonicMode
        nsView.needsDisplay = true
        nsView.displayIfNeeded()
    }
    #else
    public func makeUIView(context: Context) -> KeyboardViewClass {
        let view = KeyboardViewClass()
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        view.polyphonicMode = polyphonicMode
        return view
    }
    public func updateUIView(_ uiView: KeyboardViewClass, context: Context) {
        uiView.firstOctave = firstOctave
        uiView.octaveCount = octaveCount
        uiView.polyphonicMode = polyphonicMode
        uiView.setNeedsDisplay()
    }
    #endif

    public init(delegate: KeyboardDelegate? = nil, firstOctave: Int, octaveCount: Int, polyphonicMode: Bool) {
        self.delegate = delegate
        self.firstOctave = firstOctave
        self.octaveCount = octaveCount
        self.polyphonicMode = polyphonicMode
    }
}
