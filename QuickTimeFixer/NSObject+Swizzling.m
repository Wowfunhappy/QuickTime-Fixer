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
- (id)_canBecomeFullScreen;
@end



@implementation myMGCinematicFrameView

- (void)displayIfNeeded {
    if ([[self window] _canBecomeFullScreen] == NULL) {
        //Misleading: this actually gets a set of nine bits from MGCinematicFrameView, only one of which represents _entireBackBufferIsDirty.
        unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
        
        //Set _entireBackBufferIsDirty bit to 1
        *Ivars |= 1UL << 4;
        
        NSDisableScreenUpdates();
        [self displayIfNeededIgnoringOpacity];
        ZKOrig(void);
        NSEnableScreenUpdates();
    }
    else {
        ZKOrig(void);
    }
}

- (void)_windowChangedKeyState {
    ZKOrig(void);
    
    //Fixes fullscreen animations.
    if ([[self window] _canBecomeFullScreen] != NULL) {
        [[self window] _makeLayerBacked];
    }
    
    //Fixes window shadows.
    [[self window] update];
}

- (void)setWindowNotOpaque {
    [[self window] setOpaque:false];
}

@end



@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    
    //Fix menu bar not switching to QuickTime
    [self runApplescript: [NSMutableString stringWithFormat:@"tell application (path to frontmost application as text) to activate"]];
}

- (void)runApplescript:(NSMutableString *)scriptSource {
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *error;
    [[script executeAndReturnError:&error] stringValue];
}

@end