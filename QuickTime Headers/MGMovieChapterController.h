//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGMovieThumbnailExtractionSession, NSArray, QTMovie;

@interface MGMovieChapterController : NSObject
{
    QTMovie *_movie;
    MGMovieThumbnailExtractionSession *_thumbnailExtractionSession;
    NSArray *_chapters;
}

+ (id)keyPathsForValuesAffectingChapters;
@property(readonly, nonatomic) NSArray *chapters; // @synthesize chapters=_chapters;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)updateChapters;
@property(retain, nonatomic) QTMovie *movie;
- (void)dealloc;

@end

