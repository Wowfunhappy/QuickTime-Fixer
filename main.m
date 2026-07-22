//
//  QuickTimeFixer
//
//  This code was written by Jonathan Alland.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "ZKSwizzle/ZKSwizzle.h"

#define EMPTY_SWIZZLE_INTERFACE(CLASS_NAME, SUPERCLASS) @interface CLASS_NAME : SUPERCLASS @end

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
	ZKOrig(void);
	if (
		[self isKindOfClass:NSClassFromString(@"MGAudioPlaybackViewController")] || 
		[self isKindOfClass:NSClassFromString(@"MGVideoPlaybackViewController")]
	) {
		[self runUserScript:@"userFileOpenedScript"];
	}
}

- (void)close {
	if (
		[self isKindOfClass:NSClassFromString(@"MGAudioPlaybackViewController")] || 
		[self isKindOfClass:NSClassFromString(@"MGVideoPlaybackViewController")]
	) {
		[self runUserScript:@"userFileClosedScript"];
	}
	ZKOrig(void);
}

- (void)runUserScript:(NSString*)scriptName {	
	NSString* path = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"scpt"];
	if (path != nil) {
		NSString *scriptSource = [
			NSString stringWithFormat:@"run script (load script POSIX file \"%@\") with parameters {\"%@\"}",
			path,
			[[self valueForKey:@"document"]displayName]
		];
		[[[NSAppleScript alloc] initWithSource:scriptSource] executeAndReturnError:nil];
	}
}

@end




// Mirrors _isAnimatingFullScreen; set and cleared alongside it in -setFullScreen:duration: below.
static BOOL gQTFixAnimatingFullScreen = NO;

static const char kNeedsCheckWindowButtonsKey;
@interface QTFixer_MGCinematicFrameView : NSView
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

- (void)displayIfNeeded {
	//Fix non-video documents displaying without a background.
	
	// Don't do any of this while the fullscreen transition is animating.
	if (gQTFixAnimatingFullScreen) {
		ZKOrig(void);
		return;
	}

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

- (void)_windowChangedKeyState {
	[self setNeedsCheckWindowButtons:YES];
	[self unstickWindowButtonHoverState];
	
	ZKOrig(void);
}

- (void)setFrameSize:(struct CGSize)arg1 {
	[self setNeedsCheckWindowButtons:YES];
	// During the fullscreen transition this runs every frame, and each call would schedule its own
	// timer. The transition schedules a single one from its completion handler instead.
	if (!gQTFixAnimatingFullScreen) {
		[self performSelector:@selector(unstickWindowButtonHoverState) withObject:nil afterDelay:0.7];
	}
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




static const char kIsSettingMainViewControllerKey;

// Declarations only, so we can call these without casting everything to id.
// The first four are MGCinematicWindow properties; the last two are private NSWindow methods that
// exist in Mavericks' AppKit.
@interface NSWindow (quickTimeFixerFullScreen)
- (void)setHasRoundedCorners:(BOOL)arg1;
- (void)setAutomaticallyConstrainsFrameRect:(BOOL)arg1;
- (void)setMovingDisabled:(BOOL)arg1;
- (void)setResizingDisabled:(BOOL)arg1;
- (void)_startLiveResize;
- (void)_endLiveResize;
@end

@interface QTFixer_MGDocumentWindowController : NSWindowController
- (void)toggleFloating:(id)arg1;
- (BOOL)isFloating;
- (void)updateTitlebarVisibility;
- (struct CGSize)adjustedNaturalContentSize;
- (BOOL)isContentResizable;
- (void)resizeWindowToFitContent;
@property (nonatomic, strong) id currentMainViewController;
@end

// Bits within the bitfield storage unit that ZKHookIvar hands back for any one of these ivars.
// Order is from MGDocumentWindowController's ivar list and is identical in 10.2 and 10.3.
#define QTFIX_ISFULLSCREEN				(1U << 0)
#define QTFIX_ISANIMATINGFULLSCREEN			(1U << 1)
#define QTFIX_NEEDSRESIZEAFTERFULLSCREENEXIT		(1U << 3)

// The two file static helpers 10.3's -setFullScreen:duration: calls. They have no selectors in the
// binary, so the names are ours. The first genuinely ignores its controller argument in 10.3, so we
// simply don't take one.
static void QTFixConfigureWindowForFullScreen(NSWindow *window) {
	[window setMovingDisabled:YES];
	[window setResizingDisabled:YES];
	[[window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:NO];
	[window setAutomaticallyConstrainsFrameRect:NO];
	[window setResizeIncrements:NSMakeSize(1.0, 1.0)];
}

static void QTFixRestoreWindowFromFullScreen(QTFixer_MGDocumentWindowController *controller, NSWindow *window) {
	NSSize naturalSize = [controller adjustedNaturalContentSize];
	if (!NSEqualSizes(naturalSize, NSZeroSize)) {
		[window setContentAspectRatio:naturalSize];
	}

	[window setAutomaticallyConstrainsFrameRect:YES];
	[[window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
	[window setResizingDisabled:![controller isContentResizable]];
	[window setMovingDisabled:NO];

	if ([window screen] == nil) {
		NSScreen *firstScreen = [[NSScreen screens] objectAtIndex:0];
		[window
			setFrame:[window constrainFrameRect:[window frame] toScreen:firstScreen]
			display:YES
			animate:YES
		];
	}

	unsigned int *flags = &ZKHookIvar(controller, unsigned int, "_isFullScreen");
	if (*flags & QTFIX_NEEDSRESIZEAFTERFULLSCREENEXIT) {
		*flags &= ~QTFIX_NEEDSRESIZEAFTERFULLSCREENEXIT;
		[
			[NSRunLoop currentRunLoop] performSelector:@selector(resizeWindowToFitContent)
			target:controller
			argument:nil
			order:0
			modes:[NSArray arrayWithObject:NSRunLoopCommonModes]
		];
	}
}

@implementation QTFixer_MGDocumentWindowController

- (BOOL)isSettingMainViewController {
	return [objc_getAssociatedObject(self, &kIsSettingMainViewControllerKey) boolValue];
}

- (void)setIsSettingMainViewController:(BOOL)value {
	objc_setAssociatedObject(self, &kIsSettingMainViewControllerKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCurrentMainViewController:(id)controller {
	if ([self isSettingMainViewController]) {
		ZKOrig(void, controller);
		return;
	}

	[self setIsSettingMainViewController:YES];

	id oldValue = [self valueForKey:@"currentMainViewController"];

	if (oldValue != controller) {
		[self willChangeValueForKey:@"currentMainViewController"];
		ZKOrig(void, controller);
		[self didChangeValueForKey:@"currentMainViewController"];
	} else {
		ZKOrig(void, controller);
	}

	[self setIsSettingMainViewController:NO];
}

+ (BOOL)automaticallyNotifiesObserversOfCurrentMainViewController {
	return NO;
}

- (id)customWindowsToEnterFullScreenForWindow:(id)arg1 {
	if ([self isFloating]) {
		[self toggleFloating:nil];
	}

	return ZKOrig(id, arg1);
}

// QuickTime 10.2's Fullscreen animation is glitchy on OS X 10.9. Replace it with one derived from QuickTime 10.3.
- (void)setFullScreen:(BOOL)arg1 duration:(double)arg2 {
	[self willChangeValueForKey:@"fullScreen"];

	unsigned int *flags = &ZKHookIvar(self, unsigned int, "_isFullScreen");
	if (arg1) {
		*flags |= QTFIX_ISFULLSCREEN;
	} else {
		*flags &= ~QTFIX_ISFULLSCREEN;
	}

	NSWindow *window = [self window];
	id viewController = [self currentMainViewController];
	NSView *mainView = [viewController view];
	NSView *superview = [mainView superview];

	NSRect *savedFrame = &ZKHookIvar(self, NSRect, "_savedNonFullScreenWindowFrame");
	NSRect destinationFrame = arg1 ? [[window screen] frame] : *savedFrame;
	
	//arg2 *= 1.0; // Change animation duration if desired
	BOOL shouldAnimate = (arg2 > 0.0 && mainView != nil &&
		![[NSUserDefaults standardUserDefaults] boolForKey:@"MGFullScreenNeverAnimate"]);

	if (shouldAnimate) {
		if (arg1) {
			*savedFrame = [window frame];
			QTFixConfigureWindowForFullScreen(window);
		} else {
			[window setHasRoundedCorners:YES];
			[window setHasShadow:YES];
		}

		gQTFixAnimatingFullScreen = YES;
		[window _startLiveResize];

		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			[context setDuration:arg2];
			[context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];

			ZKHookIvar(self, unsigned int, "_isFullScreen") |= QTFIX_ISANIMATINGFULLSCREEN;
			gQTFixAnimatingFullScreen = YES;

			[(NSWindow *)[window animator] setFrame:destinationFrame display:YES];
			[self updateTitlebarVisibility];

			NSRect destInWindow = [window convertRectFromScreen:destinationFrame];
			NSRect destInSuperview = [superview convertRect:destInWindow fromView:nil];
			NSSize destInMainView = [superview convertSize:destInSuperview.size toView:mainView];

			[[NSNotificationCenter defaultCenter]
				postNotificationName:@"MGDocumentWindowControllerDidStartFullScreenAnimationNotification"
				object:self
				userInfo:[NSDictionary dictionaryWithObject:[NSValue valueWithSize:destInMainView]
				forKey:@"MGDocumentWindowControllerFullScreenAnimationDestinationMainViewBoundsSizeKey"]
			];
		} completionHandler:^{
			[[NSNotificationCenter defaultCenter]
				postNotificationName:@"MGDocumentWindowControllerDidFinishFullScreenAnimationNotification"
							  object:self];

			ZKHookIvar(self, unsigned int, "_isFullScreen") &= ~QTFIX_ISANIMATINGFULLSCREEN;
			gQTFixAnimatingFullScreen = NO;
			[[[window contentView] superview] performSelector:@selector(unstickWindowButtonHoverState)
												   withObject:nil
												   afterDelay:0.7];

			[window _endLiveResize];

			if (arg1) {
				[window setHasShadow:NO];
				[window setHasRoundedCorners:NO];
			} else {
				QTFixRestoreWindowFromFullScreen(self, window);
				ZKHookIvar(self, NSRect, "_savedNonFullScreenWindowFrame") = NSZeroRect;
			}
		}];
	} else {
		if (arg1) {
			*savedFrame = [window frame];
			QTFixConfigureWindowForFullScreen(window);
		} else {
			[window setHasRoundedCorners:YES];
			[window setHasShadow:YES];
		}

		[window setFrame:destinationFrame display:YES];

		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			[context setDuration:0.0];
			[self updateTitlebarVisibility];
		} completionHandler:nil];

		if (arg1) {
			[window setHasShadow:NO];
			[window setHasRoundedCorners:NO];
		} else {
			QTFixRestoreWindowFromFullScreen(self, window);
			*savedFrame = NSZeroRect;
		}
	}

	[self didChangeValueForKey:@"fullScreen"];
}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGDocumentController, NSDocumentController);
@implementation QTFixer_MGDocumentController

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError **)outError {

	// Disabling AVFoundation appears to:
	//	+ Allow QuickTime Framework based audio decoders to work.
	//		• With AVFoundation enabled, QuickTime does seemingly try to use these decoders, but fails.
	//		• Documents will open but not play. Console messages:
	//			• `>audiocomp> AudioComponentPlugin.cpp:75: NewInstance: error -3000 returned from Open`
	//			• `>aq> AudioQueueObject.cpp:1590: Prime: failed (-9405); will stop (66150/0 frames)`
	//	+ Allow third-party QuickTime Framework based AVI importers to work.
	//		• Presumably because with AVFoundation enabled, Apple's built-in AVI support takes priority.
	//		• (Apple's built-in AVI support fails to open many/most files.)
	//	- Disable features:
	//		• All video editing functionality
	//		• Sharing
	//	- Break Apple's native AVFoundation decoders.
	//	- Break modern Audio Component decoders.
	
	NSArray *extensionsThatForceQTKit = @[@"avi", @"flv", @"ogg", @"ogv"];
	
	BOOL shouldForceQTKit = [extensionsThatForceQTKit containsObject:[[url pathExtension] lowercaseString]];
	if ([NSEvent modifierFlags] & NSAlternateKeyMask) shouldForceQTKit = !shouldForceQTKit; // alt inverts behavior
	
	if (shouldForceQTKit) {
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
	// While not strictly necessary, this is very useful information to have in the console.
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
	ZKSwizzle(QTFixer_MGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
	ZKSwizzle(QTFixer_MGPlayerController, MGPlayerController);
	ZKSwizzle(QTFixer_QTHUDButton, QTHUDButton);
	ZKSwizzle(QTFixer_NSWindow, NSWindow);
	ZKSwizzle(QTFixer_MGDocumentWindowController, MGDocumentWindowController);
	ZKSwizzle(QTFixer_MGDocumentController, MGDocumentController);
	ZKSwizzle(QTFixer_MGAssetLoader, MGAssetLoader);
}

@end




int main() {}