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

@implementation myMGCinematicFrameView


- (bool) isAudioOnly {
    if (self.bounds.size.height < 104) {
        return true;
    }
    else {
        return false;
    }
}

- (void)fixBackground {
    NSLog(@"Fixing the background.");
    
    //Toggling this bit fixes problems for some reason.
    styleMask &= ~(1UL << 0);
    styleMask |= 1UL << 0;
    
    //This actually gets a set of nine bits from MGCinematicFrameView, only one of which represents _entireBackBufferIsDirty.
    unsigned int *Ivars = &ZKHookIvar(self, unsigned int, "_entireBackBufferIsDirty");
    
    //Set "_entireBackBufferIsDirty" bit to 1
    *Ivars |= 1UL << 4;
    
    [self displayIfNeededIgnoringOpacity];
}

- (void)displayIfNeeded { //viewWillDraw
    if ([self isAudioOnly]) {
        [self fixBackground];
    }
    ZKOrig(void);
}

@end

@implementation NSObject (Swizzling)

+ (void)load {
    ZKSwizzle(myMGCinematicFrameView, MGCinematicFrameView);
}

@end

