//
//  QuickTimeFixer
//
//  This code was written by Jonathan Alland.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "ZKSwizzle/ZKSwizzle.h"

#define EMPTY_SWIZZLE_INTERFACE(CLASS_NAME, SUPERCLASS) @interface CLASS_NAME : SUPERCLASS @end

static void runUserScript(NSString* scriptName) {
	NSString* path = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"scpt"];
	if (path != nil) {
		NSDictionary *error;
		[[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error] executeAndReturnError:nil];
	}
}

@interface NSWindow (quickTimeFixer)
- (void)_makeLayerBacked;
- (id)_canBecomeFullScreen;
- (BOOL)_processKeyboardUIKey:(id)arg1;
@end

@interface _borderView : NSView
- (void) _setHasAutoCanDrawSubviewsIntoLayer:(bool)arg1;
@end




@interface QTFixer_AVPlayerItem : AVPlayerItem
- (id)_trackWithTrackID:(int)arg1;
@end

@implementation QTFixer_AVPlayerItem
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




EMPTY_SWIZZLE_INTERFACE(QTFixer_AVAssetExportSession, AVAssetExportSession);
@implementation QTFixer_AVAssetExportSession

//Apple removed this method from AVFoundation, but all we need is the stub.
- (void)setUsesHardwareVideoEncoderIfAvailable:(BOOL)arg1 {}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGDocumentViewController, NSViewController);
@implementation QTFixer_MGDocumentViewController

- (void)loadView {
	if (
		[self isKindOfClass:NSClassFromString(@"MGAudioPlaybackViewController")] || 
		[self isKindOfClass:NSClassFromString(@"MGVideoPlaybackViewController")]
	) {
		runUserScript(@"userFileOpenedScript");
	}
	ZKOrig(void);
}

- (void)close {
	if (
		[self isKindOfClass:NSClassFromString(@"MGAudioPlaybackViewController")] || 
		[self isKindOfClass:NSClassFromString(@"MGVideoPlaybackViewController")]
	) {
		runUserScript(@"userFileClosedScript");
	}
	ZKOrig(void);
}

@end




static const char kNeedsSetHasAutoCanDrawSubviewsIntoLayerKey;
static const char kNeedsCheckWindowButtonsKey;
@interface QTFixer_MGCinematicFrameView : NSView
- (void) _setHasAutoCanDrawSubviewsIntoLayer:(bool)arg1;
@end

@implementation QTFixer_MGCinematicFrameView
/*In this class, we correct graphical issues using fixes discovered via trial and error.
 The timing of when these fixes are needed is very specific!*/

- (BOOL)needsCheckWindowButtons {
	return [objc_getAssociatedObject(self, &kNeedsCheckWindowButtonsKey) boolValue];
}

- (void)setNeedsCheckWindowButtons:(BOOL)value {
	objc_setAssociatedObject(self, &kNeedsCheckWindowButtonsKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)needsSetHasAutoCanDrawSubviewsIntoLayer {
	return [objc_getAssociatedObject(self, &kNeedsSetHasAutoCanDrawSubviewsIntoLayerKey) boolValue];
}

- (void)setNeedsSetHasAutoCanDrawSubviewsIntoLayer:(BOOL)value {
	objc_setAssociatedObject(self, &kNeedsSetHasAutoCanDrawSubviewsIntoLayerKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTitle:(id)arg1 {
	[self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
	
	// Why can't we just setCanDrawSubviewsIntoLayer here? Because it will break screen recording documents.
	[self setNeedsSetHasAutoCanDrawSubviewsIntoLayer:YES];
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
		if ([self needsSetHasAutoCanDrawSubviewsIntoLayer]) {
			//Fix FullScreen animation glitch
			[self setCanDrawSubviewsIntoLayer:true];
		}
		ZKOrig(void);
	}
}

- (void)_windowChangedKeyState {
	[self setNeedsCheckWindowButtons:YES];
	[self unstickWindowButtonHoverState];
	
	ZKOrig(void);
}

- (void)setFrameSize:(struct CGSize)arg1 {
	[self setNeedsCheckWindowButtons:YES];
	[self performSelector:@selector(unstickWindowButtonHoverState) withObject:nil afterDelay:0.7];
	ZKOrig(void, arg1);
}

- (void)unstickWindowButtonHoverState {
	if ([self needsCheckWindowButtons]) {
		//This won't always work; it depends on the location of the user's mouse at the time this code is run.
		//(This bug exists in Mountain Lion too, btw.)
		[self setNeedsCheckWindowButtons:NO];
		[[self subviews][1] viewDidEndLiveResize];
	}
}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGCinematicWindow, NSWindow);
@implementation QTFixer_MGCinematicWindow

- (void)_windowTransformAnimationDidEnd:(id)arg1 {
	ZKOrig(void, arg1);
	for (int i = 0; i <= 100; i++) {
		[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:(i * 0.01)];
	}
	// Just in case
	[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:2];
	[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:3];
	[self performSelector:@selector(invalidateShadow) withObject:nil afterDelay:5];
}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGScrollEventHandlingHUDSlider, NSObject);
@implementation QTFixer_MGScrollEventHandlingHUDSlider
//Prevent an audio glitch.
- (void)beginGestureWithEvent:(id)arg1 {}
- (void)scrollWheel:(id)arg1 {}
@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGPlayerController, NSController);
@implementation QTFixer_MGPlayerController
//Prevent an audio glitch.
- (void)increaseVolume:(id)arg1 {}
- (void)decreaseVolume:(id)arg1 {}
@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_QTHUDButton, NSControl);
@implementation QTFixer_QTHUDButton
//Tabbing between QTHUDButtons can cause QuickTime to crash. This behavior is annoying anyway.
- (BOOL)becomeFirstResponder {
	return false;
}
@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_NSWindow, NSWindow);
@implementation QTFixer_NSWindow
//Continuation of above: Tabbing between QTHUDButtons can cause QuickTime to crash.
- (void)selectKeyViewFollowingView:(id)arg1 {
	if (strcmp(object_getClassName(arg1), "NSView") != 0 && strcmp(object_getClassName(arg1), "MGPlayPauseShuttleControllerView") != 0) {
		ZKOrig(void, arg1);
	}
}
@end




@interface QTFixer_MGDocumentWindowController : NSWindowController
- (void)toggleFloating:(id)arg1;
@end
@implementation QTFixer_MGDocumentWindowController
- (id)customWindowsToEnterFullScreenForWindow:(id)arg1 {
	if (ZKHookIvar(self, int, "_isFloating")) {
		[self toggleFloating:nil];
	}
		
	return ZKOrig(id, arg1);
}
@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGDocumentController, NSDocumentController);
@implementation QTFixer_MGDocumentController

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError **)outError {
	// If AVFoundation is enabled when QuickTime opens an AVI,
	// it will use its broken AVI importer that almost never works.
	if ([[[url pathExtension] lowercaseString] isEqualToString:@"avi"]) {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MGEnableAVFoundation"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MGEnableAVFoundation"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	return ZKOrig(NSString *, url, outError);
}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGAssetLoader, NSObject);
@implementation QTFixer_MGAssetLoader

- (void)loadingDidFailWithError:(id)arg1 {
	NSLog(@"QuickTime failed to load document due to error: %@", arg1);
	ZKOrig(void, arg1);
}

@end




@implementation NSObject (main)

+ (void)load {
	ZKSwizzle(QTFixer_AVPlayerItem, AVPlayerItem);
	ZKSwizzle(QTFixer_AVAssetExportSession, AVAssetExportSession);
	ZKSwizzle(QTFixer_MGDocumentViewController, MGDocumentViewController);
	ZKSwizzle(QTFixer_MGCinematicFrameView, MGCinematicFrameView);
	ZKSwizzle(QTFixer_MGCinematicWindow, MGCinematicWindow);
	ZKSwizzle(QTFixer_MGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
	ZKSwizzle(QTFixer_MGPlayerController, MGPlayerController);
	ZKSwizzle(QTFixer_QTHUDButton, QTHUDButton);
	ZKSwizzle(QTFixer_NSWindow, NSWindow);
	ZKSwizzle(QTFixer_MGDocumentWindowController, MGDocumentWindowController);
	ZKSwizzle(QTFixer_MGDocumentController, MGDocumentController);
	ZKSwizzle(QTFixer_MGAssetLoader, MGAssetLoader);
	
	
	//Fix menu bar not switching to QuickTime.
	[[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
}

@end




int main() {}