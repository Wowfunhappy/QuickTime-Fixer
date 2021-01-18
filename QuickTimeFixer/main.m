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
    unsigned int doNotUse1; //Without this, other iVars seems to get messed up.
    bool hasSetup;
    bool needsSetBackBufferDirty;
    bool needsUpdateVolume;
    NSString *doNotUse2; //See above.
    NSString *ourLegacyMediaBridgePID;
}
@end

@interface myQTHUDSliderCell : NSSlider
@end

@interface myMGScrollEventHandlingHUDSlider : NSObject
@end

@interface myMGPlayerController : NSController
@end

@interface myQTHUDButton : NSControl
@end

@interface NSWindow (quickTimeFixer)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
@end



/*global*/

AudioDeviceID device;
UInt32 size = sizeof(AudioDeviceID);
UInt32 gChannels[2];

NSMutableArray *existingLegacyMediaBridgePIDs;

void setQTSliderVolume() {
    NSString *scriptText = [NSString stringWithFormat:@"tell application \"QuickTime Player\" to tell (every document whose name is not \"%@\" and name is not \"%@\") to set audio volume to (output volume of (get volume settings)) * 0.01", NSLocalizedString(@"Audio Recording", nil), NSLocalizedString(@"Movie Recording", nil)];
    [[[NSAppleScript alloc] initWithSource:scriptText] executeAndReturnError:nil];
}

OSStatus volumeChangedCallback (AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput, AudioDevicePropertyID inPropertyID, void* inClientData) {
    setQTSliderVolume();
    return 0;
}

void startVolumeChangedListener() {
    //Apple's deprication warnings are extremely unhelpful when there isn't anything else we can use instead...
    //(Not to mention, this code should only ever be used on OS X 10.9.)
    AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size, gChannels);
    AudioDeviceAddPropertyListener(device, gChannels[0], false, kAudioDevicePropertyVolumeScalar, (AudioDevicePropertyListenerProc) volumeChangedCallback, nil);
}

OSStatus audioDeviceChangedCallback(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
    //WARNING: This function assumes startVolumeChangedListener has already been called at least once! Please make sure that happens!
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

NSString* runShellCommand(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    task.environment = @{}; //If we don't reset this, QuickTime will try to inject the QuickTime fixer library into this task!
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", command]];
    
    NSPipe *pipe = [[NSPipe alloc] init];
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    [task setStandardOutput:pipe];
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [fileHandle readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

/*end global*/



@implementation myMGCinematicFrameView
//This class (1) fixes graphical issues, and (2) tracks and kills legacyMediaBridge instances.
//Graphical fixes were  discovered largely via brute-force trial and error, and I mostly don't understand why they work.

- (void)ghettoInit {
    needsSetBackBufferDirty = true;
    needsUpdateVolume = true;
    
    ourLegacyMediaBridgePID = @"";
    [self performSelector:@selector(findLegacyMediaBridgePID) withObject:nil afterDelay:0.5];
    
    hasSetup = true;
}

- (void)ghettoDealloc {
    if ([ourLegacyMediaBridgePID length] > 0) {
        [existingLegacyMediaBridgePIDs removeObject:ourLegacyMediaBridgePID];
        runShellCommand([NSString stringWithFormat:@"kill -n 2 %@", ourLegacyMediaBridgePID]);
    }
}

- (void)findLegacyMediaBridgePID {
    /*QuickTime interacts with QuickTime components via legacyMediaBridge, but on Mavericks, it doesn't seem to
     close the legacymediabridge.videodecompression processes once it's done with them. They stick around, eating
     up small amounts of memory (~20mb each) until the user quits QuickTime.
     
     To fix this, we need to close these processes ourself, which implies tracking their creation.
     To do so, we look for instances of legacymediabridge.videodecompression, and record their PIDs
     in a globally-accessible array. If we find exactly one PID which we haven't seen before, we can safely
     assume it belongs to us. This won't always work, but it doesn't really have to.*/
    
    NSString *stringOfFoundPIDs = runShellCommand(@"ps -A | grep -v grep | grep com.apple.legacymediabridge.videodecompression | awk '{print $1;}'");
    stringOfFoundPIDs = [stringOfFoundPIDs stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([stringOfFoundPIDs length] > 0){
        NSArray *foundPIDs = [stringOfFoundPIDs componentsSeparatedByString:@"\n"];
        
        bool alreadyFoundAUniquePID = false;
        for (int i = 0; i < [foundPIDs count]; i++) {
            if (![existingLegacyMediaBridgePIDs containsObject:[foundPIDs objectAtIndex:i]]){
                NSString *foundPID = [foundPIDs objectAtIndex:i];
                [existingLegacyMediaBridgePIDs addObject:foundPID];
                if (! alreadyFoundAUniquePID) {
                    alreadyFoundAUniquePID = true;
                    ourLegacyMediaBridgePID = foundPID;
                } else {
                    /*We found a unique PID, but we already found one! The user probably opened multiple
                    videos at once. There's no way to know which one is ours.*/
                    ourLegacyMediaBridgePID = @"";
                }
            }
        }
    }
}

- (void)displayIfNeeded {
    if (needsSetBackBufferDirty | ([[self window]inLiveResize] && (![self canBecomeFullScreen])) ) {
        /*Window backgrounds are currently glitched. To fix them, we need to do the following:
            1. Set _entireBackBufferIsDirty bit
            2. Run either [self displayIfNeededIgnoringOpacity] or [super displayIfNeeded].
                (We use the former, as it should be more efficient.)
            3. Run the original [self displayIfNeeded]

        Notably, steps two and three make no sense! We're running a varation of displayIfNeeded followed by the
        normal displayIfNeeded, which should be basically the same thing! And, yes, you _must_ call one and
        then the other—running either twice is not sufficient.*/
        
        //This is very misleading. ZKHookIvar will actually return a set of nine bits from MGCinematicFrameView. The fifth one is _entireBackBufferIsDirty.
        unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
        
        //Set the _entireBackBufferIsDirty bit to 1
        *Ivars |= 1UL << 4;
        
        //Disabling screen updates between these two steps prevents a brief flash of glitchiness.
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

- (void)setTitle:(id)arg1 {
    //Swizzling init and dealloc methods causes bad things to happen, so we need another way to initialize stuff!
    //Luckily, this method runs once when new views are created, and once when they are deallocated. Sooo...
    
    if (! hasSetup) {
        [self ghettoInit];
    }
    else {
        [self ghettoDealloc];
    }
    
    ZKOrig(void, arg1);
}

@end



@implementation myQTHUDSliderCell

//By default, the volume slider doesn't work, and it doesn't seem to be fixable. So, I've made it control the system volume instead, a la iOS.
//Frankly, I don't consider this behavior better or worse—it's just different.

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
//We made QuickTime's volume slider corrospond to the system volume. Remove some methods of changing the slider to avoid accidents.
- (void)beginGestureWithEvent:(id)arg1 {}
- (void)scrollWheel:(id)arg1 {}
@end



@implementation myMGPlayerController

//As above, we want to disable some ways to change the volume slider.
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



@implementation myQTHUDButton

- (BOOL)becomeFirstResponder {
    return false;
}

@end



@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myQTHUDSliderCell, QTHUDSliderCell);
    ZKSwizzle(myMGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
    ZKSwizzle(myMGPlayerController, MGPlayerController);
    ZKSwizzle(myQTHUDButton, QTHUDButton);
    
    //Fix menu bar not switching to QuickTime.
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
    startVolumeChangedListener();
    startAudioDeviceChangedListener();
    
    existingLegacyMediaBridgePIDs = [@[] mutableCopy];
}

@end