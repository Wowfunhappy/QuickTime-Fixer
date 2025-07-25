//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class AVPlayer, AVTrackGroup, MGLanguageAlternate, NSArray, NSString;

@interface MGPlayerLanguageController : NSObject
{
    AVPlayer *_player;
    NSString *_mediaType;
}

+ (id)keyPathsForValuesAffectingSystemLanguageAlternate;
+ (id)keyPathsForValuesAffectingAuthoredLanguageAlternate;
+ (id)keyPathsForValuesAffectingCurrentLanguageAlternate;
+ (id)keyPathsForValuesAffectingExcludedLanguageAlternates;
+ (id)keyPathsForValuesAffectingLanguageAlternates;
+ (id)keyPathsForValuesAffectingTrackGroup;
@property(retain, nonatomic) AVPlayer *player; // @synthesize player=_player;
@property(readonly, nonatomic) MGLanguageAlternate *systemLanguageAlternate;
@property(readonly, nonatomic) MGLanguageAlternate *authoredLanguageAlternate;
- (void)setCurrentForcedSubtitleLanguageForLanguageAlternate:(id)arg1;
@property(copy, nonatomic) MGLanguageAlternate *currentLanguageAlternate;
@property(readonly, nonatomic) NSArray *excludedLanguageAlternates;
@property(readonly, nonatomic) NSArray *languageAlternates;
- (id)languageAlternatesFromTracksExcludedFromAutoselection:(BOOL)arg1;
@property(readonly, nonatomic) AVTrackGroup *trackGroup;
- (void)dealloc;
- (id)init;
- (id)initWithMediaType:(id)arg1;

@end

