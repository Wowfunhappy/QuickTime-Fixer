//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGTrimViewController;

@protocol MGTrimViewControllerDelegate <NSObject>

@optional
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willStepBackwardCurrentMediaTimeToTime:(CDStruct_1b6d18a9)arg2;
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willStepForwardCurrentMediaTimeToTime:(CDStruct_1b6d18a9)arg2;
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willChangeCurrentMediaTimeToTime:(CDStruct_1b6d18a9)arg2;
- (void)trimViewControllerDidStopTrackingCurrentMediaTime:(MGTrimViewController *)arg1;
- (void)trimViewControllerWillStartTrackingCurrentMediaTime:(MGTrimViewController *)arg1;
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willStepBackwardSelectionEdge:(int)arg2 toTime:(CDStruct_1b6d18a9)arg3;
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willStepForwardSelectionEdge:(int)arg2 toTime:(CDStruct_1b6d18a9)arg3;
- (CDStruct_1b6d18a9)trimViewController:(MGTrimViewController *)arg1 willChangeSelectionEdge:(int)arg2 toTime:(CDStruct_1b6d18a9)arg3;
- (void)trimViewController:(MGTrimViewController *)arg1 didStopTrackingSelectionEdge:(int)arg2;
- (void)trimViewController:(MGTrimViewController *)arg1 willStartTrackingSelectionEdge:(int)arg2;
- (void)trimViewControllerDidCommitEditing:(MGTrimViewController *)arg1;
@end

