//
//  NSObject+Swizzling.m
//  QuickTimeFixer
//
//  Created by Jonathan Alland on 12/21/20.
//  Copyright (c) 2020 Jonathan Alland. All rights reserved.
//

#import "NSObject+Swizzling.h"
#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

#import "/Users/jonathan/Desktop/macOS_headers-master/macOS/Frameworks/AppKit/1/NSFrameView.h"

@interface myMGCinematicFrameView : NSFrameView
@end

@interface NSWindow (my)
- (void)_makeLayerBacked;
- (void)_discardWindowResizeConstraintsAndMarkAsNeedingUpdate;
- (id)_canBecomeFullScreen;
@end

@interface myMGDocumentWindowController : NSWindowController
- (void)setFullScreen:(BOOL)arg1 duration:(double)arg2;
@end



@implementation myMGCinematicFrameView

- (void)displayIfNeeded {
    
    //Misleading: this actually gets a set of nine bits from MGCinematicFrameView, only one of which represents _entireBackBufferIsDirty.
    unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
    
    //Set "_entireBackBufferIsDirty" bit to 1
    *Ivars |= 1UL << 4;
    
    [super displayIfNeeded];
    ZKOrig(void);
    
}

- (void)_windowChangedKeyState {
    ZKOrig(void);
    
    //Fixes window shadows.
    [self performSelector:@selector(shapeWindow) withObject:nil afterDelay:0];
    
    //Fixes fullscreen animations.
    if ([[self window] _canBecomeFullScreen] != NULL) {
        [[self window] _makeLayerBacked];
    }
}

- (void)setCanDrawSubviewsIntoLayer:(BOOL)arg1; {
    ZKOrig(void, true);
}

@end



@implementation myMGDocumentWindowController

//Swizzling this class is "optional", in that without it, the exit fullscreen animation will work as well as it does in Mountain Lion. But, I don't like how it looks in Mountain Lion; the default system animation is smoother! So, let's use that instead.

- (id)customWindowsToExitFullScreenForWindow:(id)arg1 {
    [self performSelector:@selector(setFullScreenDisabled) withObject:nil afterDelay:0];
    return nil;
}

- (void) setFullScreenDisabled {
    [self setFullScreen:false duration:-1];
}

@end



@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    ZKSwizzle(myMGDocumentWindowController, MGDocumentWindowController);
    
    //Fix menu bar not switching to QuickTime
    [self runApplescript: [NSMutableString stringWithFormat:@"tell application (path to frontmost application as text) to activate"]];
}

- (void)runApplescript:(NSMutableString *)scriptSource {
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *error;
    [[script executeAndReturnError:&error] stringValue];
}

@end