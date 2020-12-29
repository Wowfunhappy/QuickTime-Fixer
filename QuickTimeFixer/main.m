//
//  QuickTimeFixer
//
//  This code was written by Jonathan Alland.
//  Copyright (c) 2020 Jonathan Alland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "ZKSwizzle.h"

@interface myMGCinematicFrameView : NSView
{
    unsigned int doNotUse; //Without this, the next iVar seems to get messed up.
    bool needsSetBackBufferDirty;
    bool needsUpdateVolume;
}
@end

@interface myQTHUDSliderCell : NSSlider
@end

@interface myMGPlayerController : NSController
@end

@interface myMGScrollEventHandlingHUDSlider : NSObject
@end

@interface NSWindow (my)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
@end



/*global*/

AudioDeviceID device;
UInt32 size = sizeof(AudioDeviceID);
UInt32 gChannels[2];

void setQTSliderVolume() {
    NSString *scriptText = [NSString stringWithFormat:@"tell application \"QuickTime Player\" to tell (every document whose name is not \"%@\" and name is not \"%@\") to set audio volume to (output volume of (get volume settings)) * 0.01", NSLocalizedString(@"Audio Recording", nil), NSLocalizedString(@"Movie Recording", nil)];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}

OSStatus volumeChangedCallback (AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput, AudioDevicePropertyID inPropertyID, void* inClientData) {
    setQTSliderVolume();
    return 0;
}

void startVolumeChangedListener() {
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size, gChannels);
    AudioDeviceAddPropertyListener(device, gChannels[0], false, kAudioDevicePropertyVolumeScalar, (AudioDevicePropertyListenerProc) volumeChangedCallback, nil);
}

OSStatus audioDeviceChangedCallback(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
    /*Warning: This function assumes startVolumeChangedListener has already been called at least once! Please make sure that happens!*/
    AudioDeviceRemovePropertyListener(device, gChannels[0], false, kAudioDevicePropertyVolumeScalar, (AudioDevicePropertyListenerProc) volumeChangedCallback);
    startVolumeChangedListener();
    setQTSliderVolume();
    return 0;
}

void startAudioDeviceChangedListener() {
    AudioObjectPropertyAddress outputDeviceAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectAddPropertyListener(kAudioObjectSystemObject, &outputDeviceAddress, &audioDeviceChangedCallback, nil);
}



@implementation myMGCinematicFrameView
//Graphical issues were fixed in this class. These fixes were mostly discovered via brute-force trial and error, and I largely don't understand why they work.

- (void)setTitle:(id)arg1 {
    //This method conveniently runs once when new windows are created. We can use it like an init method.
    needsSetBackBufferDirty = true;
    needsUpdateVolume = true;
    ZKOrig(void, arg1);
}

- (void)displayIfNeeded {
    if (needsSetBackBufferDirty | ([[self window]inLiveResize] && (![self canBecomeFullScreen])) ) {
        
        //This is very misleading. ZKHookIvar will actually return a set of nine bits from MGCinematicFrameView. The fifth of these bits represents _entireBackBufferIsDirty.
        unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
        
        //Set the _entireBackBufferIsDirty bit to 1
        *Ivars |= 1UL << 4;
        
        //In order for setting the _entireBackBufferIsDirty bit to actually fix window backgrounds, we need to run either [self displayIfNeededIgnoringOpacity] or [super displayIfNeeded] (we use the former because I think it's more efficient) FOLLOWED BY the original [self displayIfNeeded] (via ZKOrig). Disabling screen updates between the two prevents a brief flash of no-background becoming visible.
        //Consider, for a moment, how little sense this makes. To fix thie problem, we need to run a varation of displayIfNeeded followed by the normal displayIfNeeded! Which should be basically the same code! And in case you're wondering, yes, you _must_ call one and then the other—simply running either of them twice won't do it.
        //But it works. So whatevs.
        
        NSDisableScreenUpdates();
        [self displayIfNeededIgnoringOpacity];
        ZKOrig(void);
        NSEnableScreenUpdates();
        
        needsSetBackBufferDirty = false;
    }
    else {
        ZKOrig(void);
    }
}

- (void)_windowChangedKeyState {
    needsSetBackBufferDirty = true;
    
    //Fixes fullscreen animations.
    if ([self canBecomeFullScreen]) {
        [[self window] _makeLayerBacked];
    }
    
    //Fixes window shadows.
    [[self window]update];
    
    if (needsUpdateVolume) {
        setQTSliderVolume();
        needsUpdateVolume = false;
    }
    
    ZKOrig(void);
}

- (bool)canBecomeFullScreen {
    return ([[self window] _canBecomeFullScreen] != NULL);
}

@end



@implementation myQTHUDSliderCell

//By default, the volume slider doesn't work, and I can't figure out why. So, I've made it control the system volume instead, as it does on iOS. I don't consider this behavior better or worse, merely different—clearly, Apple thought it was worth doing on the iPhone.

- (double)_QTHUDSliderValidateUserValue:(double)arg1 {
    [self setSystemVolume:arg1];
    return ZKOrig(double, arg1);
}

- (void) setSystemVolume: (double)volume {
    NSString *scriptText = [NSString stringWithFormat:@"set volume output volume %f * 100", volume];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}

@end



@implementation myMGScrollEventHandlingHUDSlider
//We made QuickTime's volume slider corrospond to the system volume. To avoid accidents, let's remove some methods of changing the slider.
- (void)beginGestureWithEvent:(id)arg1 {}
- (void)scrollWheel:(id)arg1 {}
@end



@implementation myMGPlayerController

//Again, we want to disable some ways to change the volume slider.
- (void)increaseVolume:(id)arg {}
- (void)decreaseVolume:(id)arg1 {}

- (void)changeVolumeToMinimum:(id)arg1 {
    [[[NSAppleScript alloc] initWithSource:@"set volume with output muted"] executeAndReturnError:nil];
    
    NSString *scriptText = [NSString stringWithFormat:@"tell application \"QuickTime Player\" to tell (every document whose name is not \"%@\" and name is not \"%@\") to set audio volume to 0", NSLocalizedString(@"Audio Recording", nil), NSLocalizedString(@"Movie Recording", nil)];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}
- (void)changeVolumeToMaximum:(id)arg1 {
    [[[NSAppleScript alloc] initWithSource:@"set volume without output muted"] executeAndReturnError:nil];
    setQTSliderVolume();
}

@end



@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myQTHUDSliderCell, QTHUDSliderCell);
    ZKSwizzle(myMGPlayerController, MGPlayerController);
    ZKSwizzle(myMGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
    
    //Fix menu bar not switching to QuickTime
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
    startVolumeChangedListener();
    startAudioDeviceChangedListener();
}

@end