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

@interface myMGCinematicFrameView : NSView
{
    unsigned int doNotUse; //Without this, the next iVar seems to get messed up.
    bool needSetBackBufferDirty;
}
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
}

- (void)setTitle:(id)arg1 {
    needSetBackBufferDirty = true;
    ZKOrig(void, arg1);
}

- (bool)canBecomeFullScreen {
    return ([[self window] _canBecomeFullScreen] != NULL);
}

@end



@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
    
    //Fix menu bar not switching to QuickTime
    [[[NSAppleScript alloc] initWithSource:@"tell application (path to frontmost application as text) to activate"] executeAndReturnError:nil];
    
}

@end