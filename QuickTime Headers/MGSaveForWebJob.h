//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "MGJob.h"

@class MGPosterImageOperation, MGReadMeOperation, MGReferenceMovieOperation, NSDictionary, NSError, NSSet, NSString, NSURL;

@interface MGSaveForWebJob : MGJob
{
    MGPosterImageOperation *_posterImageOperation;
    MGReferenceMovieOperation *_referenceMovieOperation;
    MGReadMeOperation *_readMeOperation;
    NSSet *_exportOperations;
    NSString *_runningStatusString;
    NSString *_finishedStatusString;
    NSURL *_resultURL;
    NSError *_error;
    NSString *_name;
    float _progress;
    BOOL _canReveal;
    NSDictionary *_saveParameters;
}

+ (id)keyPathsForValuesAffectingCanReveal;
+ (id)saveForWebJobWithMediaComposition:(id)arg1 exportSettings:(id)arg2 saveParameters:(id)arg3;
@property(nonatomic) BOOL canReveal; // @synthesize canReveal=_canReveal;
@property(copy, nonatomic) NSString *finishedStatusString; // @synthesize finishedStatusString=_finishedStatusString;
@property(copy, nonatomic) NSURL *resultURL; // @synthesize resultURL=_resultURL;
@property(retain, nonatomic) NSError *error; // @synthesize error=_error;
@property(copy, nonatomic) NSString *runningStatusString; // @synthesize runningStatusString=_runningStatusString;
@property(nonatomic) float progress; // @synthesize progress=_progress;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (id)operations;
- (void)dealloc;
- (id)initWithMediaComposition:(id)arg1 exportSettings:(id)arg2 saveParameters:(id)arg3;

@end

