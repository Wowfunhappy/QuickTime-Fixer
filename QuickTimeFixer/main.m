//
//  NSObject+Swizzling.m
//  QuickTimeFixer
//
//  Created by Jonathan Alland on 12/21/20.
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

@interface NSWindow (my)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
@end



/*global functions*/

void setAudioVolume() {
    NSString *scriptText = [NSString stringWithFormat:@"tell application \"QuickTime Player\" to tell (every document whose name is not \"%@\" and name is not \"%@\") to set audio volume to (output volume of (get volume settings)) * 0.01", NSLocalizedString(@"Audio Recording", nil), NSLocalizedString(@"Movie Recording", nil)];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}

OSStatus volumeChangedCallback ( AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput, AudioDevicePropertyID inPropertyID, void* inClientData) {
    setAudioVolume();
    return 0;
}



@implementation myMGCinematicFrameView

- (void)setTitle:(id)arg1 {
    //This method conveniently runs once when new windows are created. We can use it like an init method.
    needsSetBackBufferDirty = true;
    needsUpdateVolume = true;
    ZKOrig(void, arg1);
}

- (void)displayIfNeeded {
    if (needsSetBackBufferDirty | ([[self window]inLiveResize] && (![self canBecomeFullScreen])) ) {
        
        //Misleading: this actually gets a set of nine bits from MGCinematicFrameView, only one of which represents _entireBackBufferIsDirty.
        unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
        
        //Set _entireBackBufferIsDirty bit to 1
        *Ivars |= 1UL << 4;
        
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
        setAudioVolume();
        needsUpdateVolume = false;
    }
    
    ZKOrig(void);
}

- (bool)canBecomeFullScreen {
    return ([[self window] _canBecomeFullScreen] != NULL);
}

@end



@implementation myQTHUDSliderCell

- (double)_QTHUDSliderValidateUserValue:(double)arg1 {
    [self setSystemVolume:arg1];
    return ZKOrig(double, arg1);
}

- (void) setSystemVolume: (double)volume {
    NSString *scriptText = [NSString stringWithFormat:@"set volume output volume %f * 100", volume];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}

@end



@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myQTHUDSliderCell, QTHUDSliderCell);
    
    //Fix menu bar not switching to QuickTime
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
    //Listen for system volume changes
    AudioDeviceID device;
    UInt32 size = sizeof(AudioDeviceID);
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    UInt32 gChannels[2];
    AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size, gChannels);
    AudioDeviceAddPropertyListener(device, gChannels[0], false, kAudioDevicePropertyVolumeScalar, (AudioDevicePropertyListenerProc) volumeChangedCallback, nil);
}

@end