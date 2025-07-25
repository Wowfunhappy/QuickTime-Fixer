//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "AVPlayerItem.h"

@class NSValue;

@interface AVPlayerItem (MGAdditions)
+ (id)playerItemWithMediaClip:(id)arg1 inMediaComposition:(id)arg2 assetProvider:(id)arg3;
+ (id)playerItemWithAsset:(id)arg1 transform:(struct CGAffineTransform)arg2 presentationSize:(struct CGSize)arg3 timeRange:(CDStruct_e83c9415)arg4;
+ (id)keyPathsForValuesAffectingDurationWithinEndTimes;
+ (id)keyPathsForValuesAffectingCurrentTimeWithinEndTimes;
+ (id)keyPathsForValuesAffectingPlaybackTimeRange;
+ (id)keyPathsForValuesAffectingPlaybackMaxTime;
+ (id)keyPathsForValuesAffectingPlaybackMinTime;
+ (id)keyPathsForValuesAffectingHasChapters;
+ (id)keyPathsForValuesAffectingCanChangePlayingRate;
+ (id)keyPathsForValuesAffectingCanChangeVolume;
- (id)assetTracksWithMediaType:(id)arg1;
@property(readonly) CDStruct_1b6d18a9 durationWithinEndTimes;
@property CDStruct_1b6d18a9 currentTimeWithinEndTimes;
@property(readonly) CDStruct_e83c9415 playbackTimeRange;
@property(readonly) NSValue *playbackMaxTime;
@property(readonly) NSValue *playbackMinTime;
@property(readonly) BOOL hasChapters;
@property(readonly) BOOL canChangePlayingRate;
@property(readonly) BOOL canChangeVolume;
@end

