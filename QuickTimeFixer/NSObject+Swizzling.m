//
//  NSObject+Swizzling.m
//  QuickTimeFixer
//
//  Created by Jonathan Alland on 12/21/20.
//  Copyright (c) 2020 Jonathan Alland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+Swizzling.h"
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "ZKSwizzle.h"

@interface myMGCinematicFrameView : NSView
{
    unsigned int doNotUse; //Without this, the next iVar seems to get messed up.
    bool needSetBackBufferDirty;
}
- (id)_subtreeDescription;
@end

@interface myQTHUDSliderCell : NSSlider
- (void)accessibilityPerformAction:(id)arg1;
- (id)accessibilityActionDescription:(id)arg1;
- (id)accessibilityActionNames;
- (void)accessibilitySetValue:(id)arg1 forAttribute:(id)arg2;
- (BOOL)accessibilityIsAttributeSettable:(id)arg1;
- (id)accessibilityAttributeValue:(id)arg1;
- (id)accessibilityAttributeNames;
@end

@interface NSWindow (my)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
@end



@implementation myMGCinematicFrameView

- (void)displayIfNeeded {
    if (needSetBackBufferDirty | ([[self window]inLiveResize] && (![self canBecomeFullScreen])) ) {
        
        //Misleading: this actually gets a set of nine bits from MGCinematicFrameView, only one of which represents _entireBackBufferIsDirty.
        unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
        
        //Set _entireBackBufferIsDirty bit to 1
        *Ivars |= 1UL << 4;
        
        NSDisableScreenUpdates();
        [self displayIfNeededIgnoringOpacity];
        ZKOrig(void);
        NSEnableScreenUpdates();
        
        needSetBackBufferDirty = false;
    }
    else {
        ZKOrig(void);
    }
}

- (void)_windowChangedKeyState {
    needSetBackBufferDirty = true;
    
    //Fixes fullscreen animations.
    if ([self canBecomeFullScreen]) {
        [[self window] _makeLayerBacked];
    }
    
    //Fixes window shadows.
    [[self window]update];
    
    ZKOrig(void);
    
    
    //testing area
    //NSLog(@"Subviews: %@", [self _subtreeDescription]);
    
}

- (void)setTitle:(id)arg1 {
    needSetBackBufferDirty = true;
    ZKOrig(void, arg1);
}

- (bool)canBecomeFullScreen {
    return ([[self window] _canBecomeFullScreen] != NULL);
}



@end


@implementation myQTHUDSliderCell

- (void)stopTracking:(struct CGPoint)arg1 at:(struct CGPoint)arg2 inView:(id)arg3 mouseIsUp:(BOOL)arg4 {
    if ([self isVolumeSlider]) {
    }
}

- (double)_QTHUDSliderValidateUserValue:(double)arg1 {
    /*NSString *str = [NSString stringWithFormat: @"set volume output volume %f * 100", [self floatValue]];
    [[[NSAppleScript alloc] initWithSource:str] executeAndReturnError:nil];*/
    
    return ZKOrig(double, arg1);
}

- (BOOL)isVolumeSlider {
    return ([self maxValue] == 1.000000);
}

- (double) getCurrSystemVolume {
    NSAppleEventDescriptor *result = [[[NSAppleScript alloc] initWithSource:@"return (output volume of (get volume settings))"] executeAndReturnError:nil];
    double volume = [[NSNumber numberWithInt:[result int32Value]] doubleValue] * 0.01;
    return volume;
}

- (id)initWithCoder:(id)arg1 {
    
    NSLog(@"I'm here");
    
    AudioDeviceID device;
    UInt32 size = sizeof(AudioDeviceID);
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    UInt32 gChannels[2];
    AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size, gChannels);
    
    AudioDeviceAddPropertyListener(device, gChannels[0], false, kAudioDevicePropertyVolumeScalar, (AudioDevicePropertyListenerProc) volumeChangedCallback, (__bridge void *)(self));
    
    return ZKOrig (id, arg1);
}

OSStatus volumeChangedCallback ( AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput, AudioDevicePropertyID inPropertyID, void* inClientData) {
    objc_msgSend((__bridge id)(inClientData), @selector(volumeChanged), nil);
    return 0;
}
- (void) volumeChanged {
    [self setFloatValue:[self getCurrSystemVolume]];
}

@end



@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myQTHUDSliderCell, QTHUDSliderCell);
    
    
    //Fix menu bar not switching to QuickTime
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
}

@end