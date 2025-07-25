//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "AVAsset.h"

@class AVAssetTrack, NSString;

@interface AVAsset (MGAdditions)
+ (id)keyPathsForValuesAffectingMainVideoTrackPreferredSize;
+ (id)keyPathsForValuesAffectingMainVideoTrackPreferredTransform;
+ (id)keyPathsForValuesAffectingMainVideoTrackNaturalSize;
+ (id)keyPathsForValuesAffectingMainAudioTrack;
+ (id)keyPathsForValuesAffectingMainVideoTrack;
- (BOOL)valuesForKeysAreFinishedLoading:(id)arg1;
@property(readonly) struct CGSize mainVideoTrackPreferredSize;
@property(readonly) struct CGAffineTransform mainVideoTrackPreferredTransform;
@property(readonly) struct CGSize mainVideoTrackNaturalSize;
@property(readonly) AVAssetTrack *mainAudioTrack;
@property(readonly) AVAssetTrack *mainVideoTrack;
@property(readonly) NSString *localizedDisplayName;
- (BOOL)canPassthroughExport;
@end

