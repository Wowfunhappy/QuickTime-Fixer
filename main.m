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




// ===== Fix for export error -12780 caused by malformed source MP4s =====
//
// Some MP4 files (notably yt-dlp / DASH downloads) end their audio track with a final
// zero-duration sample, giving the audio time-to-sample table ('stts') more than one
// entry. OS X 10.9's AVFoundation export engine (FigRemaker) fails any export whose
// composition references such an audio track, with the generic error -12780 -- even
// though playback of these files works fine. (Determined empirically: exports of such
// files fail in a minimal test program on 10.9; rewriting the table as a single uniform
// entry makes them succeed, and no other difference matters.)
//
// The fix: when QuickTime's export machinery loads a source movie, scan its audio
// 'stts' tables. If a table shows the problem pattern (uniform sample durations plus a
// single odd-duration final sample), make a temporary copy of the file with the table
// rewritten as one uniform entry -- a ~20 byte change, no re-encode -- and let the
// export read that copy instead. Copies are cached per (size, mtime, name), so each
// source file is only copied once. Playback is untouched: this hook is only reached
// through the export path's asset loading.

static unsigned int QTFixRead32(const unsigned char *p) {
	return ((unsigned int)p[0] << 24) | ((unsigned int)p[1] << 16) | ((unsigned int)p[2] << 8) | p[3];
}

// One patchable stts box: rewrite as a single entry of sampleCount x sampleDelta.
// fileOffset is the absolute offset of the stts box in the file.
struct QTFixSttsPatch {
	unsigned long long fileOffset;
	unsigned int boxSize;
	unsigned int sampleCount;
	unsigned int sampleDelta;
};

// Walks box children in [start, end) of moov data, collecting patchable audio stts boxes.
// Recursion is restricted to the containers on the trak->stbl path.
static void QTFixScanBoxes(const unsigned char *moov, unsigned long long moovFileOffset,
		unsigned long long start, unsigned long long end, BOOL *trakIsAudio,
		struct QTFixSttsPatch *patches, unsigned int *patchCount, unsigned int maxPatches) {
	unsigned long long pos = start;
	while (pos + 8 <= end) {
		unsigned long long size = QTFixRead32(moov + pos);
		const unsigned char *type = moov + pos + 4;
		if (size < 8) break;  // 64-bit and zero-size boxes don't occur inside moov's path
		if (pos + size > end) break;

		if (memcmp(type, "trak", 4) == 0) {
			BOOL isAudio = NO;
			QTFixScanBoxes(moov, moovFileOffset, pos + 8, pos + size, &isAudio, patches, patchCount, maxPatches);
		} else if (memcmp(type, "mdia", 4) == 0 || memcmp(type, "minf", 4) == 0 || memcmp(type, "stbl", 4) == 0) {
			QTFixScanBoxes(moov, moovFileOffset, pos + 8, pos + size, trakIsAudio, patches, patchCount, maxPatches);
		} else if (memcmp(type, "hdlr", 4) == 0 && trakIsAudio != NULL) {
			// handler subtype is at payload offset 8 (component subtype)
			if (size >= 24 && memcmp(moov + pos + 16, "soun", 4) == 0) {
				*trakIsAudio = YES;
			}
		} else if (memcmp(type, "stts", 4) == 0 && trakIsAudio != NULL && *trakIsAudio && *patchCount < maxPatches) {
			unsigned int entryCount = QTFixRead32(moov + pos + 12);
			if (entryCount >= 2 && size >= 16 + 8ULL * entryCount) {
				// Problem pattern: all entries share one delta, except a final 1-sample entry.
				unsigned int uniformDelta = QTFixRead32(moov + pos + 16 + 4);
				unsigned long long totalSamples = 0;
				BOOL uniform = YES;
				for (unsigned int i = 0; i < entryCount - 1; i++) {
					if (QTFixRead32(moov + pos + 16 + 8 * i + 4) != uniformDelta) uniform = NO;
					totalSamples += QTFixRead32(moov + pos + 16 + 8 * i);
				}
				unsigned int lastCount = QTFixRead32(moov + pos + 16 + 8 * (entryCount - 1));
				unsigned int lastDelta = QTFixRead32(moov + pos + 16 + 8 * (entryCount - 1) + 4);
				totalSamples += lastCount;
				if (uniform && lastCount == 1 && lastDelta != uniformDelta &&
						uniformDelta > 0 && totalSamples <= 0xFFFFFFFFULL) {
					patches[*patchCount].fileOffset = moovFileOffset + pos;
					patches[*patchCount].boxSize = (unsigned int)size;
					patches[*patchCount].sampleCount = (unsigned int)totalSamples;
					patches[*patchCount].sampleDelta = uniformDelta;
					(*patchCount)++;
				}
			}
		}
		pos += size;
	}
}

// Finds patchable audio stts boxes in an MP4/MOV file. Returns the number found.
static unsigned int QTFixFindAudioSttsPatches(NSString *path,
		struct QTFixSttsPatch *patches, unsigned int maxPatches) {
	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
	if (fh == nil) return 0;

	unsigned int found = 0;
	@try {
		unsigned long long fileSize = [fh seekToEndOfFile];
		unsigned long long pos = 0;
		while (pos + 8 <= fileSize) {
			[fh seekToFileOffset:pos];
			NSData *header = [fh readDataOfLength:16];
			if ([header length] < 8) break;
			const unsigned char *h = [header bytes];
			unsigned long long size = QTFixRead32(h);
			if (size == 1 && [header length] >= 16) {
				size = ((unsigned long long)QTFixRead32(h + 8) << 32) | QTFixRead32(h + 12);
			} else if (size == 0) {
				size = fileSize - pos;
			}
			if (size < 8) break;

			if (memcmp(h + 4, "moov", 4) == 0) {
				if (size > 200 * 1024 * 1024) break;  // absurd moov; bail
				[fh seekToFileOffset:pos];
				NSData *moov = [fh readDataOfLength:(NSUInteger)size];
				if ([moov length] == size) {
					QTFixScanBoxes([moov bytes], pos, 8, size, NULL, patches, &found, maxPatches);
				}
				break;
			}
			pos += size;
		}
	} @catch (NSException *exception) {
		found = 0;
	}
	[fh closeFile];
	return found;
}

// Resolves an asset URL (possibly a file-reference URL with a ?applesecurityscope=
// query, as stored by QuickTime's media clips) to a plain filesystem path.
static NSString *QTFixLocalPathForAssetURL(NSURL *url) {
	if (url == nil || ![url isFileURL]) return nil;
	NSString *absolute = [url absoluteString];
	NSRange query = [absolute rangeOfString:@"?"];
	if (query.location != NSNotFound) {
		url = [NSURL URLWithString:[absolute substringToIndex:query.location]];
	}
	NSURL *pathURL = [url filePathURL];
	if (pathURL == nil) pathURL = url;
	return [pathURL path];
}

// If the file at the given URL has the malformed audio stts pattern, returns the URL of
// a patched (cached) temporary copy. Returns nil when no substitution is needed.
static NSURL *QTFixPatchedCopyIfNeeded(NSURL *url) {
	NSString *path = QTFixLocalPathForAssetURL(url);
	if (path == nil) return nil;

	struct QTFixSttsPatch patches[8];
	unsigned int patchCount = QTFixFindAudioSttsPatches(path, patches, 8);
	if (patchCount == 0) return nil;

	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *attributes = [fm attributesOfItemAtPath:path error:nil];
	unsigned long long sourceSize = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
	NSTimeInterval mtime = [[attributes objectForKey:NSFileModificationDate] timeIntervalSince1970];

	NSString *cacheDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QTFixPatchedMedia"];
	[fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
	NSString *cachePath = [cacheDir stringByAppendingPathComponent:
		[NSString stringWithFormat:@"%llx-%llx-%@", sourceSize, (unsigned long long)mtime, [path lastPathComponent]]];

	if (![fm fileExistsAtPath:cachePath]) {
		NSLog(@"QuickTimeFixer: %@ has a malformed audio sample table that would make the "
			"export fail with error -12780; making a patched copy for the export to use.", [path lastPathComponent]);
		NSString *inProgressPath = [cachePath stringByAppendingString:@".inprogress"];
		[fm removeItemAtPath:inProgressPath error:nil];
		NSError *copyError = nil;
		if (![fm copyItemAtPath:path toPath:inProgressPath error:&copyError]) {
			NSLog(@"QuickTimeFixer: could not copy source movie (%@); export will use the original.", copyError);
			return nil;
		}

		NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:inProgressPath];
		if (fh == nil) {
			[fm removeItemAtPath:inProgressPath error:nil];
			return nil;
		}
		for (unsigned int i = 0; i < patchCount; i++) {
			// stts layout: size(4) 'stts'(4) versionAndFlags(4) entryCount(4) entries(8 each).
			// Rewrite as a single entry covering every sample, and zero the leftover
			// entry space (it lies inside the box but beyond the declared entries).
			unsigned char payload[16];
			payload[0] = 0; payload[1] = 0; payload[2] = 0; payload[3] = 1;
			payload[4] = (patches[i].sampleCount >> 24) & 0xFF;
			payload[5] = (patches[i].sampleCount >> 16) & 0xFF;
			payload[6] = (patches[i].sampleCount >> 8) & 0xFF;
			payload[7] = patches[i].sampleCount & 0xFF;
			payload[8] = (patches[i].sampleDelta >> 24) & 0xFF;
			payload[9] = (patches[i].sampleDelta >> 16) & 0xFF;
			payload[10] = (patches[i].sampleDelta >> 8) & 0xFF;
			payload[11] = patches[i].sampleDelta & 0xFF;
			@try {
				[fh seekToFileOffset:patches[i].fileOffset + 12];
				[fh writeData:[NSData dataWithBytes:payload length:12]];
				NSUInteger leftover = patches[i].boxSize - 24;
				if (leftover > 0) {
					[fh writeData:[NSMutableData dataWithLength:leftover]];
				}
			} @catch (NSException *exception) {
				NSLog(@"QuickTimeFixer: failed to patch copy: %@", exception);
				[fh closeFile];
				[fm removeItemAtPath:inProgressPath error:nil];
				return nil;
			}
		}
		[fh closeFile];
		[fm removeItemAtPath:cachePath error:nil];
		if (![fm moveItemAtPath:inProgressPath toPath:cachePath error:nil]) {
			[fm removeItemAtPath:inProgressPath error:nil];
			return nil;
		}
	}
	return [NSURL fileURLWithPath:cachePath];
}

EMPTY_SWIZZLE_INTERFACE(QTFixer_AVAssetExportSession, AVAssetExportSession);
@implementation QTFixer_AVAssetExportSession

//Apple removed this method from AVFoundation, but all we need is the stub.
- (void)setUsesHardwareVideoEncoderIfAvailable:(BOOL)arg1 {}

@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_NSFileManager, NSFileManager);
@implementation QTFixer_NSFileManager

// QuickTime's export names its temporary output file ".MG-<uuid>" — a dot-file. It then adjusts
// that URL's extension with URLByDeletingPathExtension / URLByAppendingPathExtension:. On
// OS X 10.9, URLByDeletingPathExtension treats a dot-file's entire name as an extension and
// deletes it (10.8 left dot-files alone), so ".../(A Document Being Saved)/.MG-<uuid>" collapses
// into ".../(A Document Being Saved)" and the appended extension renames the *directory*. The
// export session is then pointed at a directory URL and fails with error -12780. Dropping the
// leading dot gives a name whose extension handling works the same on both OS versions.
- (id)temporaryLocationForSavingURL:(id)arg1 error:(id *)arg2 {
	NSURL *result = ZKOrig(id, arg1, arg2);
	NSString *name = [result lastPathComponent];
	if ([name hasPrefix:@"."]) {
		result = [[result URLByDeletingLastPathComponent]
			URLByAppendingPathComponent:[name substringFromIndex:1]];
	}
	return result;
}

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

// Typed access to the MGAutovisibilityController methods we call.
@protocol QTFixAutovisibility <NSObject>
- (void)hide;
- (void)cancelAutomaticallyShowDueToKeyDown;
@end

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




static const char kQTFixDeferredKeydownShowKey;

EMPTY_SWIZZLE_INTERFACE(QTFixer_MGAutovisibilityController, NSObject);
@implementation QTFixer_MGAutovisibilityController

// The key-down monitor schedules this as a common-modes run loop perform, and a menu key
// equivalent's highlight flash spins the run loop (in a tracking mode) BEFORE the menu action
// runs — so the keystroke that toggles fullscreen would show the HUD first and start the
// transition second. Re-defer the show into NSDefaultRunLoopMode only: that can't fire during
// the tracking spin, so it runs after the key equivalent's dispatch has fully completed. If the
// keystroke did start a transition, setFullScreen:duration:'s cancelAutomaticallyShowDueToKeyDown
// has cleared _willShowDueToKeyDown by then and the original implementation does nothing. For any
// other keystroke the show still happens, one run loop turn later. Works with any fullscreen
// keyboard shortcut, including custom ones set in System Preferences.
- (void)showDueToKeyDownIfNeeded {
	if (objc_getAssociatedObject(self, &kQTFixDeferredKeydownShowKey)) {
		objc_setAssociatedObject(self, &kQTFixDeferredKeydownShowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		if (gQTFixAnimatingFullScreen) {
			return;
		}
		ZKOrig(void);
		return;
	}

	objc_setAssociatedObject(self, &kQTFixDeferredKeydownShowKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self performSelector:@selector(showDueToKeyDownIfNeeded)
			   withObject:nil
			   afterDelay:0.0
				  inModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

// Cancelling (which setFullScreen:duration: does when a transition starts) also cancels the
// re-deferred perform above, since it targets the same selector — but the deferral flag must be
// cleared with it, or the next keydown show would mistake itself for a deferred fire.
- (void)cancelAutomaticallyShowDueToKeyDown {
	objc_setAssociatedObject(self, &kQTFixDeferredKeydownShowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	ZKOrig(void);
}


@end




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGVideoPlaybackViewController, NSViewController);
@implementation QTFixer_MGVideoPlaybackViewController

// The fullscreen shortcut (⌃⌘F) also registers with the autovisibility controller's key-down
// monitor, which would fade the hidden HUD in just as the transition begins. The monitor's
// "deferred" show can't be cancelled from within setFullScreen:duration: — the menu-highlight
// flash of the key equivalent spins the run loop, firing the show before the menu action runs.
// So refuse it here, when the monitor examines the keystroke: a control+command chord is a menu
// shortcut, not playback interaction. Genuine playback keys (space, arrows, …) are unaffected.
- (BOOL)autovisibilityController:(id)arg1 shouldAutomaticallyShowDueToKeyDownEvent:(id)arg2 inView:(id)arg3 {
	NSUInteger flags = [(NSEvent *)arg2 modifierFlags];
	if ((flags & NSControlKeyMask) && (flags & NSCommandKeyMask)) {
		return NO;
	}
	if (gQTFixAnimatingFullScreen) {
		return NO;
	}
	return ZKOrig(BOOL, arg1, arg2, arg3);
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




EMPTY_SWIZZLE_INTERFACE(QTFixer_MGNibViewMenuItem, NSMenuItem);
@implementation QTFixer_MGNibViewMenuItem

// Chapter menu items normally install a custom view (from MGChapterMenuItemView.nib) when they
// receive NSMenuDidBeginTrackingNotification. That view's title label is hardcoded white, which is
// correct for the video chapter menu (QuickTime gives it a dark, Dock-style appearance) but
// unreadable against the audio chapter menu, which is a standard white menu. On Mavericks the
// notification fires before menuNeedsUpdate: has created the items, so the first time the audio
// chapter menu opens the items miss it and draw as ordinary (readable) text items; on every later
// open the now-cached items catch the notification and turn white-on-white. Suppress the view
// loading for the audio menu only, so every open matches the readable first one.
- (void)menuDidBeginTracking:(id)arg1 {
	id chapterMenuController = [[(NSMenuItem *)self menu] delegate];
	if ([chapterMenuController respondsToSelector:@selector(delegate)]) {
		id playbackViewController = [(id)chapterMenuController delegate];
		if ([playbackViewController isKindOfClass:NSClassFromString(@"MGAudioPlaybackViewController")]) {
			return;
		}
	}
	ZKOrig(void, arg1);
}

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
// These are MGCinematicWindow properties.
@interface NSWindow (quickTimeFixerFullScreen)
- (void)setHasRoundedCorners:(BOOL)arg1;
- (void)setAutomaticallyConstrainsFrameRect:(BOOL)arg1;
- (void)setMovingDisabled:(BOOL)arg1;
- (void)setResizingDisabled:(BOOL)arg1;
- (id)titlebarView;
@end

// Private window server API, stable on our frozen OS. CGSSetWindowTransform scales/positions a
// window's existing backing store entirely on the window server, with no app-side redraw — the same
// mechanism Exposé uses. This lets us animate the fullscreen zoom at 60fps: profiling showed the
// stock animation was jumpy because every tick of an NSWindow frame animation re-lays-out, re-renders
// (via a full client-side OpenGL pass), and re-uploads the entire window.
typedef int CGSConnectionID;
extern CGSConnectionID CGSDefaultConnectionForThread(void);
extern CGError CGSSetWindowTransform(CGSConnectionID cid, uint32_t windowID, CGAffineTransform transform);

static volatile long gQTFixZoomGeneration = 0;

// Bumped on every animated setFullScreen:duration: call; a pending chrome-fade completion from an
// older transition checks it and bails instead of starting a stale zoom.
static long gQTFixTransitionGeneration = 0;

// YES while a transition holds an [NSCursor hide] to keep a hidden cursor hidden. See
// setFullScreen:duration:.
static BOOL gQTFixCursorHideHeld = NO;


// NSScreen-space rect (global, bottom-left origin) → CG global rect (top-left origin).
static CGRect QTFixCGRectFromNSScreenRect(NSRect rect) {
	CGFloat primaryHeight = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
	return CGRectMake(rect.origin.x, primaryHeight - NSMaxY(rect), rect.size.width, rect.size.height);
}

// Window server transform that displays a window whose backing store is backingSize scaled into the
// CG-global rect. Empirically verified on 10.9: the transform maps screen points to window points,
// so a window naturally placed at (x, y) has transform {1, 0, 0, 1, -x, -y}.
static CGAffineTransform QTFixTransformForRect(CGRect rect, CGSize backingSize) {
	CGFloat sx = backingSize.width / rect.size.width;
	CGFloat sy = backingSize.height / rect.size.height;
	return CGAffineTransformMake(sx, 0, 0, sy, -rect.origin.x * sx, -rect.origin.y * sy);
}

// kCAMediaTimingFunctionDefault, i.e. the cubic bezier with control points (0.25, 0.1), (0.25, 1.0).
static double QTFixEase(double x) {
	const double c1x = 0.25, c1y = 0.1, c2x = 0.25, c2y = 1.0;
	if (x <= 0.0) return 0.0;
	if (x >= 1.0) return 1.0;
	double u = x;
	for (int i = 0; i < 8; i++) {
		double omu = 1.0 - u;
		double xu = 3.0*c1x*omu*omu*u + 3.0*c2x*omu*u*u + u*u*u;
		double dxdu = 3.0*c1x*(omu*omu - 2.0*omu*u) + 3.0*c2x*(2.0*omu*u - u*u) + 3.0*u*u;
		if (dxdu < 1e-6) break;
		u -= (xu - x) / dxdu;
		if (u < 0.0) u = 0.0;
		if (u > 1.0) u = 1.0;
	}
	double omu = 1.0 - u;
	return 3.0*c1y*omu*omu*u + 3.0*c2y*omu*u*u + u*u*u;
}

// Immediately displays the window scaled into fromRect, then animates it to toRect. The ticking
// runs on a background thread so main thread stalls (AppKit redraws menu bar items with freshly
// compiled OpenCL kernels during the transition, among other things) can't drop animation frames.
// Each tick is a single cheap window server call. The completion runs on the main thread; a newer
// zoom (or generation bump) cancels both the ticking and the pending completion.
static void QTFixAnimateWindowZoom(NSWindow *window, CGRect fromRect, CGRect toRect, double duration, void (^completion)(void)) {
	CGSConnectionID cid = CGSDefaultConnectionForThread();
	uint32_t windowID = (uint32_t)[window windowNumber];
	CGSize backingSize = [window frame].size;
	long generation = ++gQTFixZoomGeneration;

	CGSSetWindowTransform(cid, windowID, QTFixTransformForRect(fromRect, backingSize));

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		double start = CACurrentMediaTime();
		for (long frame = 1; ; frame++) {
			if (gQTFixZoomGeneration != generation) return;

			double t = duration > 0.0 ? (CACurrentMediaTime() - start) / duration : 1.0;
			if (t > 1.0) t = 1.0;
			double e = QTFixEase(t);

			CGRect r;
			r.origin.x = fromRect.origin.x + (toRect.origin.x - fromRect.origin.x) * e;
			r.origin.y = fromRect.origin.y + (toRect.origin.y - fromRect.origin.y) * e;
			r.size.width = fromRect.size.width + (toRect.size.width - fromRect.size.width) * e;
			r.size.height = fromRect.size.height + (toRect.size.height - fromRect.size.height) * e;
			CGSSetWindowTransform(cid, windowID, QTFixTransformForRect(r, backingSize));

			if (t >= 1.0) break;
			double delay = (start + frame / 60.0) - CACurrentMediaTime();
			if (delay > 0) usleep((useconds_t)(delay * 1e6));
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			if (gQTFixZoomGeneration != generation) return;
			completion();
		});
	});
}

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
		// The window geometry changes below make the window server cancel an active
		// setHiddenUntilMouseMoves: (they count as synthetic mouse moves), which would flash
		// the cursor at the end of the zoom. NSCursor's counted hide is immune to mouse moves,
		// so hold one for the duration of the transition; the completion trades it back for
		// setHiddenUntilMouseMoves:, keeping the cursor hidden until the mouse really moves.
		BOOL cursorWasHidden = !CGCursorIsVisible();
		if (cursorWasHidden && !gQTFixCursorHideHeld) {
			gQTFixCursorHideHeld = YES;
			[NSCursor hide];
		}

		// If we're cancelling an exit animation that never finished, the window's frame is still
		// fullscreen-sized and *savedFrame still holds the real windowed frame — keep it.
		BOOL wasMidAnimation = gQTFixAnimatingFullScreen;

		ZKHookIvar(self, unsigned int, "_isFullScreen") |= QTFIX_ISANIMATINGFULLSCREEN;
		gQTFixAnimatingFullScreen = YES;

		if (arg1) {
			if (!wasMidAnimation) {
				*savedFrame = [window frame];
			}
			QTFixConfigureWindowForFullScreen(window);
		} else {
			[window setHasRoundedCorners:YES];
			[window setHasShadow:YES];
		}

		// Unlike the stock animation, the window is laid out and rendered at its destination size
		// exactly once, and the zoom scales that one rendering on the window server. Because the
		// whole rendering scales, the titlebar and playback HUD must not be part of it — chrome
		// visibly shrinking/growing with the window looks wrong. If chrome is showing, it first
		// fades out at natural size exactly like the mouse-idle timeout (phase one), and only
		// then does the zoom run (phase two). When chrome is already hidden — the common case
		// when leaving fullscreen — the zoom starts immediately.
		long transitionGeneration = ++gQTFixTransitionGeneration;

		void (^performZoom)(double) = ^(double zoomDuration) {
			// On entry the resize below happens with screen updates disabled, so nothing is
			// visible until the zoom's from-transform has shrunk the fullscreen-sized window
			// back into the old frame.
			NSDisableScreenUpdates();

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				[context setDuration:0.0];

				// Snap chrome to fully hidden in case anything re-showed it during the fade.
				// Inside this zero-duration group the animator-proxy fades apply instantly.
				@try {
					[(id<QTFixAutovisibility>)[viewController valueForKey:@"autovisibilityController"] hide];
				} @catch (NSException *exception) {}

				// Hides the titlebar when entering. When exiting, the titlebar instead
				// reappears with the final relayout in the zoom's completion.
				if (arg1) {
					[self updateTitlebarVisibility];
				}

				NSRect destInWindow = [window convertRectFromScreen:destinationFrame];
				NSRect destInSuperview = [superview convertRect:destInWindow fromView:nil];
				NSSize destInMainView = [superview convertSize:destInSuperview.size toView:mainView];

				[[NSNotificationCenter defaultCenter]
					postNotificationName:@"MGDocumentWindowControllerDidStartFullScreenAnimationNotification"
					object:self
					userInfo:[NSDictionary dictionaryWithObject:[NSValue valueWithSize:destInMainView]
					forKey:@"MGDocumentWindowControllerFullScreenAnimationDestinationMainViewBoundsSizeKey"]
				];
			} completionHandler:nil];

			CGRect fromRect, toRect;
			if (arg1) {
				fromRect = QTFixCGRectFromNSScreenRect(ZKHookIvar(self, NSRect, "_savedNonFullScreenWindowFrame"));
				toRect = QTFixCGRectFromNSScreenRect(destinationFrame);
				[window setFrame:destinationFrame display:YES];
			} else {
				fromRect = QTFixCGRectFromNSScreenRect([window frame]);
				toRect = QTFixCGRectFromNSScreenRect(destinationFrame);
				// Bake the chrome-hidden state into the window before the zoom starts scaling it.
				[window displayIfNeeded];
			}

			QTFixAnimateWindowZoom(window, fromRect, toRect, zoomDuration, ^{
				if (!arg1) {
					// Give the window its real (small) frame back and let the titlebar reappear.
					// The relayout happens with screen updates disabled so the swap from
					// "fullscreen rendering scaled down" to "real windowed rendering" is a
					// single visual change. The Finish notification is posted before the
					// titlebar update because its handler undoes the autovisibility hide-state
					// from the start of the animation, which would otherwise keep the titlebar
					// hidden here.
					NSDisableScreenUpdates();
					[window setFrame:destinationFrame display:NO];

					[[NSNotificationCenter defaultCenter]
						postNotificationName:@"MGDocumentWindowControllerDidFinishFullScreenAnimationNotification"
									  object:self];

					[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
						[context setDuration:0.0];
						[self updateTitlebarVisibility];
					} completionHandler:nil];
					[window displayIfNeeded];
					CGSSetWindowTransform(
						CGSDefaultConnectionForThread(),
						(uint32_t)[window windowNumber],
						QTFixTransformForRect(QTFixCGRectFromNSScreenRect(destinationFrame), destinationFrame.size)
					);
					NSEnableScreenUpdates();
				} else {
					[[NSNotificationCenter defaultCenter]
						postNotificationName:@"MGDocumentWindowControllerDidFinishFullScreenAnimationNotification"
									  object:self];
				}

				ZKHookIvar(self, unsigned int, "_isFullScreen") &= ~QTFIX_ISANIMATINGFULLSCREEN;
				gQTFixAnimatingFullScreen = NO;
				[[[window contentView] superview] performSelector:@selector(unstickWindowButtonHoverState)
													   withObject:nil
													   afterDelay:0.7];

				if (arg1) {
					[window setHasShadow:NO];
					[window setHasRoundedCorners:NO];
				} else {
					QTFixRestoreWindowFromFullScreen(self, window);
					ZKHookIvar(self, NSRect, "_savedNonFullScreenWindowFrame") = NSZeroRect;
				}

				if (gQTFixCursorHideHeld) {
					gQTFixCursorHideHeld = NO;
					[NSCursor setHiddenUntilMouseMoves:YES];
					[NSCursor unhide];
				}
			});
			NSEnableScreenUpdates();
		};

		// The keystroke that toggles fullscreen also registers with the autovisibility
		// controller's key-down monitor, which schedules a deferred HUD show — so a hidden HUD
		// would start fading in just as the transition begins. That scheduled show hasn't fired
		// yet (it's a run loop perform and we're still in the same event dispatch), so cancel it
		// before looking at what's visible.
		@try {
			[[viewController valueForKey:@"autovisibilityController"]
				performSelector:@selector(cancelAutomaticallyShowDueToKeyDown)];
		} @catch (NSException *exception) {}

		// Phase one: if the titlebar or the playback HUD is currently visible, fade it out at
		// natural size with the native auto-hide before any scaling happens.
		BOOL chromeVisible = NO;
		@try {
			NSView *controlsView = [viewController valueForKey:@"controlsView"];
			chromeVisible = (controlsView != nil && ![controlsView isHidden] && [controlsView alphaValue] > 0.0);
		} @catch (NSException *exception) {}
		if (!chromeVisible && [window respondsToSelector:@selector(titlebarView)]) {
			NSView *titlebarView = [(id)window titlebarView];
			chromeVisible = (titlebarView != nil && ![titlebarView isHidden] && [titlebarView alphaValue] > 0.0);
		}

		if (chromeVisible) {
			// The whole transition still takes arg2: the chrome fade spends its share up front
			// and the zoom is shortened to catch up, so we end in sync with the system-side
			// transition just like the stock animation did. The fade matches the mouse-idle
			// timeout's 0.25s unless arg2 is too short to fit it.
			double fadeDuration = MIN(0.25, arg2 * 0.5);
			double zoomDuration = arg2 - fadeDuration;

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				[context setDuration:fadeDuration];
				@try {
					[(id<QTFixAutovisibility>)[viewController valueForKey:@"autovisibilityController"] hide];
				} @catch (NSException *exception) {}
				if (arg1) {
					[self updateTitlebarVisibility];
				}
			} completionHandler:^{
				if (gQTFixTransitionGeneration != transitionGeneration) return;
				performZoom(zoomDuration);
			}];
		} else {
			performZoom(arg2);
		}
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

// Export-path asset loading. Substitutes a patched copy for source movies whose
// malformed audio sample tables would make the export fail with error -12780.
// (Playback loads assets through MGAssetLoader instance methods, not this one,
// so it is unaffected.)
+ (id)synchronouslyLoadedAssetWithURL:(id)arg1 assetOptions:(id)arg2 keysForInitialAssetValuesToLoad:(id)arg3 error:(id *)arg4 {
	NSURL *substitute = QTFixPatchedCopyIfNeeded((NSURL *)arg1);
	if (substitute != nil) {
		NSLog(@"QuickTimeFixer: export will read %@ instead of %@", substitute, arg1);
		return ZKOrig(id, substitute, arg2, arg3, arg4);
	}
	return ZKOrig(id, arg1, arg2, arg3, arg4);
}

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
	// Fix for export error -12780
	ZKSwizzle(QTFixer_NSFileManager, NSFileManager);
	ZKSwizzle(QTFixer_MGDocumentViewController, MGDocumentViewController);
	ZKSwizzle(QTFixer_MGCinematicFrameView, MGCinematicFrameView);
	ZKSwizzle(QTFixer_MGAutovisibilityController, MGAutovisibilityController);
	ZKSwizzle(QTFixer_MGVideoPlaybackViewController, MGVideoPlaybackViewController);
	ZKSwizzle(QTFixer_MGScrollEventHandlingHUDSlider, MGScrollEventHandlingHUDSlider);
	ZKSwizzle(QTFixer_MGPlayerController, MGPlayerController);
	ZKSwizzle(QTFixer_MGNibViewMenuItem, MGNibViewMenuItem);
	ZKSwizzle(QTFixer_QTHUDButton, QTHUDButton);
	ZKSwizzle(QTFixer_NSWindow, NSWindow);
	ZKSwizzle(QTFixer_MGDocumentWindowController, MGDocumentWindowController);
	ZKSwizzle(QTFixer_MGDocumentController, MGDocumentController);
	ZKSwizzle(QTFixer_MGAssetLoader, MGAssetLoader);
}

@end




int main() {}