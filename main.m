//
//  QuickTimeFixer
//
//  This code was written by Jonathan Alland.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "ZKSwizzle/ZKSwizzle.h"



@interface myAVPlayerItem : AVPlayerItem
- (id)_trackWithTrackID:(int)arg1;
@end

@interface myAVAssetExportSession : AVAssetExportSession
@end

@interface myMGDocumentViewController : NSViewController
@end

@interface myMGCinematicFrameView : NSView
{
	unsigned int doNotUse1; //Without this, other iVars will be corrupted.
	bool needsCheckWindowButtons; //As many as three bools appears to be safe.
	bool needsSetHasAutoCanDrawSubviewsIntoLayer;
}
- (void) _setHasAutoCanDrawSubviewsIntoLayer:(bool)arg1;
@end

@interface myMGCinematicWindow : NSWindow
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

@interface _borderView : NSView
- (void) _setHasAutoCanDrawSubviewsIntoLayer:(bool)arg1;
@end

@interface myMGDocumentWindowController : NSWindowController
- (void)toggleFloating:(id)arg1;
@end




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



@implementation myMGDocumentViewController

- (void)loadView {
	[self runUserScript: @"userFileOpenedScript"];
	ZKOrig(void);
}

- (void)close {
	[self runUserScript: @"userFileClosedScript"];
	ZKOrig(void);
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
	needsSetHasAutoCanDrawSubviewsIntoLayer = true;
	ZKOrig(void, arg1);
}

- (void)displayIfNeeded {
	
	if ( [[self window] _canBecomeFullScreen] == NULL ) {
		//Fix non-video documents displaying without a background.
		
		//This is very misleading. ZKHookIvar will return a set of nine (!) bits from MGCinematicFrameView.
		//The fifth of these bits represents _entireBackBufferIsDirty.
		unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
		
		//Set the _entireBackBufferIsDirty bit to 1
		*Ivars |= 1UL << 4;
		
		// Disabling screen updates here prevents a brief flash of glitchiness.
		NSDisableScreenUpdates();
		[super displayIfNeeded];
		ZKOrig(void);
		NSEnableScreenUpdates();
		
		// I think I might finally semi-understand why this works. Decompilers show that [self displayIfNeeded]
		// calls [super displayIfNeeded] at the end. I think [super displayIfNeeded] re-breaks whatever
		// [self displayIfNeeded] fixes. However, [super displayIfNeeded] won't do anything if it's not "needed"!
		// By calling the super implementation first, we prevent it from being necessary later, and so the breakage
		// happen before the fix instead of the other way around. If we also disable screen updates during the
		// brief moment of breakage, it never becomes visible to the user.
	}
	else {
		if (needsSetHasAutoCanDrawSubviewsIntoLayer) {
			//Fix FullScreen animation glitch
			[self _setHasAutoCanDrawSubviewsIntoLayer:true];
			needsSetHasAutoCanDrawSubviewsIntoLayer = false;
		}
		ZKOrig(void);
	}
}

- (void)_windowChangedKeyState {
	needsCheckWindowButtons = true;
	[self unstickWindowButtonHoverState];
	
	ZKOrig(void);
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



@implementation myMGCinematicWindow

- (void)_windowTransformAnimationDidEnd:(id)arg1 {
	if ([self _canBecomeFullScreen] != NULL) {
		//Ensure window shadows appear. Different delay needed for different videos.
		[self invalidateShadow];
		[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:0.1];
		[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:0.5];
	}
	ZKOrig(void, arg1);
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
	
	return ZKOrig(id, arg1);
}

@end



@implementation NSObject (main)

+ (void)load {
	ZKSwizzle(myAVPlayerItem, AVPlayerItem);
	ZKSwizzle(myAVAssetExportSession, AVAssetExportSession);
	ZKSwizzle(myMGDocumentViewController, MGDocumentViewController);
	ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
	ZKSwizzle(myMGCinematicWindow, MGCinematicWindow);
	ZKSwizzle(myMGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
	ZKSwizzle(myMGPlayerController, MGPlayerController);
	ZKSwizzle(myQTHUDButton, QTHUDButton);
	ZKSwizzle(myNSWindow, NSWindow);
	ZKSwizzle(myMGDocumentWindowController, MGDocumentWindowController);
	
	//Fix menu bar not switching to QuickTime.
	[[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
}

@end
