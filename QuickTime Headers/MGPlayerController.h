//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

#import "QTHUDTimelineCellDelegate.h"

@class AVPlayer, MGPlayerControllerSelection;

@interface MGPlayerController : NSObject <QTHUDTimelineCellDelegate>
{
    AVPlayer *_player;
    MGPlayerControllerSelection *_selection;
    BOOL _periodicallyUpdatesTime;
    CDStruct_1b6d18a9 _timeUpdateInterval;
    double _timeUpdateResolution;
    BOOL _jogging;
}

+ (id)keyPathsForValuesAffectingSelection;
+ (id)playerControllerWithPlayer:(id)arg1;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (BOOL)handleScrollWheel:(id)arg1;
- (BOOL)handleBeginGestureWithEvent:(id)arg1;
- (BOOL)wouldHandleBeginGestureWithEvent:(id)arg1;
- (BOOL)handleSwipeWithEvent:(id)arg1;
- (BOOL)handleKeyDown:(id)arg1 eventResponse:(unsigned long long *)arg2;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (void)changeVolumeToMaximum:(id)arg1;
- (void)changeVolumeToMinimum:(id)arg1;
- (void)decreaseVolume:(id)arg1;
- (void)increaseVolume:(id)arg1;
- (void)toggleMuted:(id)arg1;
- (void)gotoEndOfSeekableRanges:(id)arg1;
- (void)skipBackwardThirtySeconds:(id)arg1;
- (void)stepBackward:(id)arg1;
- (void)stepForward:(id)arg1;
- (void)gotoPreviousChapter:(id)arg1;
- (void)gotoNextChapter:(id)arg1;
- (id)chapters;
- (void)gotoEnd:(id)arg1;
- (void)gotoBeginning:(id)arg1;
- (void)scanBackward:(id)arg1;
- (void)scanForward:(id)arg1;
- (void)togglePlaying:(id)arg1;
- (void)autoplay:(id)arg1;
- (void)whileNotAdvancingCurrentItemPerformBlock:(CDUnknownBlockType)arg1;
@property(nonatomic, getter=isJogging) BOOL jogging;
@property(nonatomic) double timeUpdateResolution;
@property(nonatomic) CDStruct_1b6d18a9 timeUpdateInterval;
@property(nonatomic) BOOL periodicallyUpdatesTime;
@property(readonly, nonatomic) id selection;
- (void)updateSelectionTimeUpdateInterval;
@property(retain, nonatomic) AVPlayer *player;
- (void)dealloc;
- (void)invalidateSelection;
- (id)init;
- (CDStruct_900afa40)timelineCell:(id)arg1 willChangeTimeValue:(CDStruct_900afa40)arg2;

@end

