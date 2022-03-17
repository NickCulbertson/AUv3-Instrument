//
//  InstrumentAUv3AudioUnit.h
//  InstrumentAUv3
//
//  Created by Nick Culbertson on 3/17/22.
//

#import <AudioToolbox/AudioToolbox.h>
#import "InstrumentAUv3DSPKernelAdapter.h"

// Define parameter addresses.
extern const AudioUnitParameterID myParam1;

@interface InstrumentAUv3AudioUnit : AUAudioUnit

@property (nonatomic, readonly) InstrumentAUv3DSPKernelAdapter *kernelAdapter;
- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
