//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGAutovisibilityController, NSEvent, NSView;

@protocol MGAutovisibilityControllerOwner <NSObject>
- (void)hideForAutovisibilityController:(MGAutovisibilityController *)arg1 dueToTimeout:(BOOL)arg2;
- (void)showForAutovisibilityController:(MGAutovisibilityController *)arg1;

@optional
- (BOOL)autovisibilityController:(MGAutovisibilityController *)arg1 shouldAutomaticallyShowDueToKeyDownEvent:(NSEvent *)arg2 inView:(NSView *)arg3;
@end

