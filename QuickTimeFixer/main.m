//
//  QuickTimeFixer
//
//  This code was written by Jonathan Alland.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "ZKSwizzle.h"

@interface myAVPlayerItem : AVPlayerItem
- (id)_trackWithTrackID:(int)arg1;
@end

@interface myAVAssetExportSession : AVAssetExportSession
@end

@interface myMGCinematicFrameView : NSView
{
    /*ZKSwizzle doesn't seem to handle instance variables properly. This is unfortunate, because we need them.
     If you must add a new iVar, test carefully to ensure no one else is messing with them...*/
    unsigned int doNotUse1; //Without this, other iVars get messed up.
    bool hasSetup;
    bool needsSetBackBufferDirty;
    bool needsCheckWindowButtons;
    NSString *doNotUse2; //See above.
    NSString *ourLegacyMediaBridgePID;
}
@end

@interface myQTHUDButton : NSControl
@end

@interface myMGScrollEventHandlingHUDSlider : NSObject
@end

@interface myMGPlayerController : NSController
@end

@interface NSWindow (quickTimeFixer)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
@end



/*global*/

NSMutableArray *existingLegacyMediaBridgePIDs;

NSString* runShellCommand(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    task.environment = @{}; //If we don't reset this, launchd will try to inject QuickTimeFixer into our NSTask!
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



@implementation myAVPlayerItem
//Apple removed these methods from AVFoundation, but QuickTime needs them!

- (int)selectedTrackIDInTrackGroup:(id)trackGroup {
    NSArray *trackIds = [trackGroup trackIDs];
    for (int i = 0; i < [trackIds count]; i++) {
        AVAssetTrack *currentTrack = [self _trackWithTrackID: [[trackIds objectAtIndex:i]intValue]];
        if ([currentTrack isEnabled]) {
            return [[trackIds objectAtIndex:i]intValue];
        }
    }
    return -1;
}

- (void)selectTrackWithID:(int)trackNum inTrackGroup:(id)trackGroup {
    NSArray *trackIds = [trackGroup trackIDs];
    for (int i = 0; i < [trackIds count]; i++) {
        if ([[trackIds objectAtIndex:i]intValue] == trackNum) {
            [[self _trackWithTrackID: [[trackIds objectAtIndex:i]intValue]] setEnabled: true];
        } else {
            [[self _trackWithTrackID: [[trackIds objectAtIndex:i]intValue]] setEnabled: false];
        }
    }
}

@end



@implementation myAVAssetExportSession
//Apple removed this method from AVFoundation, but all we need is the stub.

- (void)setUsesHardwareVideoEncoderIfAvailable:(BOOL)arg1 {}

@end



@implementation myMGCinematicFrameView
//In this class, we (1) fix graphical issues, and (2) track and kill legacyMediaBridge instances.
//Graphical fixes were  discovered via trial and error, and I largely don't understand why they work.

- (void)setTitle:(id)arg1 {
    //Swizzling init and dealloc methods causes bad things to happen, so we need another way to initialize stuff!
    //Luckily, this method runs once when new views are created, and once when they are deallocated. Sooo...
    
    if (! hasSetup) {
        [self phonyInit];
    }
    else {
        [self phonyDealloc];
    }
    ZKOrig(void, arg1);
}

- (void)phonyInit {
    needsSetBackBufferDirty = true;
    
    ourLegacyMediaBridgePID = @"";
    [self performSelector:@selector(findLegacyMediaBridgePID) withObject:nil afterDelay:0.5];
    
    //A process that should, but does not, quit on its own. Unlike its cousin, it's easy to deal with.
    runShellCommand(@"killall -SIGINT com.apple.legacymediabridge.componentregistry");
    
    hasSetup = true;
}

- (void)phonyDealloc {
    if ([ourLegacyMediaBridgePID length] > 0) {
        [existingLegacyMediaBridgePIDs removeObject:ourLegacyMediaBridgePID];
        [self performSelector:@selector(killProcess:) withObject:ourLegacyMediaBridgePID afterDelay:1];
    }
}

- (void)killProcess:(NSString*)pid {
    runShellCommand([NSString stringWithFormat:@"kill -n 2 %@", pid]);
}

- (void)findLegacyMediaBridgePID {
    /*QuickTime interacts with QuickTime components via legacyMediaBridge.
     On Mavericks, it won't close the legacymediabridge.videodecompression processes when it's done with them,
     so they waste ~ 20mb of memory each, until the user quits QuickTime.
     
     Which means we need to close them ourselves.
     Which means we need to know which ones can be safely closed.
     Which means we need to track their creation.
     
     We'll look for instances of legacymediabridge.videodecompression, and record their PIDs in a globally-
     accessible array. If we find exactly one PID which we haven't seen before, we can safely assume it belongs
     to us. This won't always work, but it doesn't have to.*/
    
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
                    videos at once; there's no way to know which one is ours.*/
                    ourLegacyMediaBridgePID = @"";
                }
            }
        }
    }
}

- (void)displayIfNeeded {
    if ( needsSetBackBufferDirty || ![self canBecomeFullScreen] ) {
        /*This is where we fix a majority of the graphical glitches. We need to:
            1. Set _entireBackBufferIsDirty to true.
            2. Run either [self displayIfNeededIgnoringOpacity] or [super displayIfNeeded].
                (We'll use the former, because I think it's more efficient.)
            3. Run the original [self displayIfNeeded]

        Notably, steps two and three make no sense! We're running a varation of displayIfNeeded followed by the
        normal displayIfNeeded, which should be basically the same thing. And, yes, you _must_ call one and
        then the other—running either twice is not sufficient.*/
        
        //This is very misleading. ZKHookIvar will return a set of nine (!) bits from MGCinematicFrameView.
        //The fifth of these bits represents _entireBackBufferIsDirty.
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
    
    needsCheckWindowButtons = true;
    [self unstickWindowButtonHoverState];
    
    ZKOrig(void);
}

- (bool)canBecomeFullScreen {
    return ([[self window] _canBecomeFullScreen] != NULL);
}

- (void)setFrameSize:(struct CGSize)arg1 {
    needsCheckWindowButtons = true;
    [self performSelector:@selector(unstickWindowButtonHoverState) withObject:nil afterDelay:0.7];
    ZKOrig(void, arg1);
}

- (void)unstickWindowButtonHoverState {
    if (needsCheckWindowButtons) {
        //This won't always work; it depends on the location of the user's mouse at the time this code is run.
        needsCheckWindowButtons = false;
        [[self subviews][1] viewDidEndLiveResize];
    }
}

@end



@implementation myQTHUDButton
//Disable the cause of a graphical glitch.
- (BOOL)becomeFirstResponder {
    return false;
}
@end



@implementation myMGScrollEventHandlingHUDSlider
//Prevent an audio glitch.
- (void)beginGestureWithEvent:(id)arg1 {}
- (void)scrollWheel:(id)arg1 {}
@end



@implementation myMGPlayerController
//Prevent an audio glitch.
- (void)increaseVolume:(id)arg {}
- (void)decreaseVolume:(id)arg1 {}
@end



@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myAVPlayerItem, AVPlayerItem);
    ZKSwizzle(myAVAssetExportSession, AVAssetExportSession);
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myQTHUDButton, QTHUDButton);
    ZKSwizzle(myMGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
    ZKSwizzle(myMGPlayerController, MGPlayerController);
    
    //Fix menu bar not switching to QuickTime.
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
    existingLegacyMediaBridgePIDs = [@[] mutableCopy];
}

@end