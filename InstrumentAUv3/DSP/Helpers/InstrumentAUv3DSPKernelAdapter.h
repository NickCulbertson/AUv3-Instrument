//
//  InstrumentAUv3DSPKernelAdapter.h
//  InstrumentAUv3
//
//  Created by Nick Culbertson on 3/17/22.
//

#import <AudioToolbox/AudioToolbox.h>

@class AudioUnitViewController;

NS_ASSUME_NONNULL_BEGIN

@interface InstrumentAUv3DSPKernelAdapter : NSObject

@property (nonatomic) AUAudioFrameCount maximumFramesToRender;
@property (nonatomic, readonly) AUAudioUnitBus *inputBus;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (AUValue)valueForParameter:(AUParameter *)parameter;

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END
