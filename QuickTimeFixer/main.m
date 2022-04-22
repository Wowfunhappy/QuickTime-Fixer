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

@interface myMGDocumentViewController : NSViewController
@end

@interface myMGCinematicFrameView : NSView
{
    /*Swizzled iVars aren't handled correctly and can be curropted. These appear to be safe, but avoid adding more!*/
    unsigned int doNotUse1; //Without this, other iVars will be corrupted.
    bool hasSetup;
    bool needsSetBackBufferDirty;
    bool needsCheckWindowButtons;
}
@end

@interface myMGScrollEventHandlingHUDSlider : NSObject
@end

@interface myMGPlayerController : NSController
@end

@interface myQTHUDButton : NSControl
@end

@interface myNSWindow : NSWindow
@end

@interface NSWindow (quickTimeFixer)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
- (BOOL)_processKeyboardUIKey:(id)arg1;
@end

@interface myMGDocumentWindowController : NSWindowController
- (void)toggleFloating:(id)arg1;
@end



/*global*/

NSMutableArray *existingLegacyMediaBridgePIDs;

NSString* runShellCommand(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    task.environment = @{}; //If we don't reset this, launchd may try to inject QuickTimeFixer into our NSTask!
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
        int currTrackID = [[trackIds objectAtIndex:i]intValue];
        AVAssetTrack *currentTrack = [self _trackWithTrackID: currTrackID];
        if ([currentTrack isEnabled]) {
            return currTrackID;
        }
    }
    return -1;
}

- (void)selectTrackWithID:(int)trackID inTrackGroup:(id)trackGroup {
    NSArray *trackIds = [trackGroup trackIDs];
    for (int i = 0; i < [trackIds count]; i++) {
        int currTrackID = [[trackIds objectAtIndex:i]intValue];
        if (currTrackID == trackID) {
            [[self _trackWithTrackID: currTrackID] setEnabled: true];
        } else {
            [[self _trackWithTrackID: currTrackID] setEnabled: false];
        }
    }
}

@end



@implementation myAVAssetExportSession
//Apple removed this method from AVFoundation, but all we need is the stub.

- (void)setUsesHardwareVideoEncoderIfAvailable:(BOOL)arg1 {}

@end



static NSString *ourLegacyMediaBridgePID;
@implementation myMGDocumentViewController

/*QuickTime interacts with QuickTime components via legacyMediaBridge processes.
 Unfortunately, when the QuickTime document associated with a legacymediabridge.videodecompression process is closed,
 the legacymediabridge.videodecompression process keeps running, wasting around 20mb of memory (per process)
 until the user quits QuickTime. This bug can be observed in vanilla QuickTime 10.2 on Mountain Lion. ;)
 
 To fix Apple's bug, need to kill these legacyMediaBridge processes when they are no longer needed.
 To do that, we need to know which processes are no longer needed.
 To do that, we need to know which processes are associated with which documents.
 To do that, we need to track when each process was created.
 To do that, we'll look for instances of legacymediabridge.videodecompression every time a new document is opened,
 and record their PIDs in a globally-accessible array. If we find exactly one PID which we haven't seen before,
 we'll assume the new process belongs to our new document. This won't always work, but it doesn't have to.*/

- (void)loadView {
    objc_setAssociatedObject(self, &ourLegacyMediaBridgePID, @"", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self performSelector:@selector(findLegacyMediaBridgePID) withObject:nil afterDelay:0.5];
    
    [self runUserScript: @"userFileOpenedScript"];
    
    ZKOrig(void);
}

- (void)close {
    [self runUserScript: @"userFileClosedScript"];
    if (objc_getAssociatedObject(self, &ourLegacyMediaBridgePID) != nil) {
        [existingLegacyMediaBridgePIDs removeObject:objc_getAssociatedObject(self, &ourLegacyMediaBridgePID)];
        [self performSelector:@selector(killProcess:) withObject:objc_getAssociatedObject(self, &ourLegacyMediaBridgePID) afterDelay:1];
    }
    
    ZKOrig(void);
}

- (void)killProcess:(NSString*)pid {
    runShellCommand([NSString stringWithFormat:@"kill -n 2 %@", pid]);
}

- (void)findLegacyMediaBridgePID {
    
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
                    objc_setAssociatedObject(self, &ourLegacyMediaBridgePID, foundPID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                } else {
                    /*We found a unique PID, but we already found one!
                     The user probably opened multiple videos at once. There's no way to know which one is ours.*/
                    objc_setAssociatedObject(self, &ourLegacyMediaBridgePID, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
        }
    }
}

- (void)runUserScript:(NSString*)scriptName {
    NSString* path = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"scpt"];
    if (path != nil) {
        NSDictionary *error;
        [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error] executeAndReturnError:nil];
    }
}

@end



@implementation myMGCinematicFrameView
/*In this class, we correct graphical issues using fixes discovered via trial and error.
 The timing of when these fixes are needed is very specific!*/

- (void)setTitle:(id)arg1 {
    //Swizzling init and dealloc methods causes bad things to happen. Luckily, this method runs once when new views are created.
    
    if (! hasSetup) {
        hasSetup = true;
        needsSetBackBufferDirty = true;
        
        [self performSelector:@selector(finishSetup) withObject:nil afterDelay:0.1];

    }
    
    ZKOrig(void, arg1);
}


- (void)finishSetup {
    //Fixes fullscreen animations glitches. See also: myMGDocumentWindowController
    if ([self canBecomeFullScreen]) {
        [[self window] _makeLayerBacked];
    }
}

- (void)displayIfNeeded {
    if ( needsSetBackBufferDirty || ![self canBecomeFullScreen] ) {
        /*This is where we fix a majority of the graphical glitches. We need to:
         1. Set _entireBackBufferIsDirty to true.
         2. Run either [self displayIfNeededIgnoringOpacity] or [super displayIfNeeded].
         (We'll use the former, because I think it's more efficient?)
         3. Run the original [self displayIfNeeded].
         
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
        //(This bug exists in Mountain Lion too, btw.)
        needsCheckWindowButtons = false;
        [[self subviews][1] viewDidEndLiveResize];
    }
}

@end



@implementation myMGScrollEventHandlingHUDSlider
//Prevent an audio glitch.
- (void)beginGestureWithEvent:(id)arg1 {}
- (void)scrollWheel:(id)arg1 {}
@end



@implementation myMGPlayerController
//Prevent an audio glitch.
- (void)increaseVolume:(id)arg1 {}
- (void)decreaseVolume:(id)arg1 {}
@end



@implementation myQTHUDButton
//Tabbing between QTHUDButtons can cause QuickTime to crash. This behavior is annoying anyway.
- (BOOL)becomeFirstResponder {
    return false;
}
@end



@implementation myNSWindow
//Continuation of above: Tabbing between QTHUDButtons can cause QuickTime to crash.
- (void)selectKeyViewFollowingView:(id)arg1 {
    if (strcmp(object_getClassName(arg1), "NSView") != 0 && strcmp(object_getClassName(arg1), "MGPlayPauseShuttleControllerView") != 0) {
        ZKOrig(void, arg1);
    }
}

@end



@implementation myMGDocumentWindowController

- (id)customWindowsToEnterFullScreenForWindow:(id)arg1 {
    if (ZKHookIvar(self, int, "_isFloating")) {
        [self toggleFloating:nil];
    }
    
    //Fixes fullscreen animation glitches. See also: myMGCinematicFrameView.
    [[self window] _makeLayerBacked];
    return ZKOrig(id, arg1);
}

@end


@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myAVPlayerItem, AVPlayerItem);
    ZKSwizzle(myAVAssetExportSession, AVAssetExportSession);
    ZKSwizzle(myMGDocumentViewController, MGDocumentViewController);
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myMGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
    ZKSwizzle(myMGPlayerController, MGPlayerController);
    ZKSwizzle(myQTHUDButton, QTHUDButton);
    ZKSwizzle(myNSWindow, NSWindow);
    ZKSwizzle(myMGDocumentWindowController, MGDocumentWindowController);
    
    //Fix menu bar not switching to QuickTime.
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
    existingLegacyMediaBridgePIDs = [@[] mutableCopy];
}

@end
