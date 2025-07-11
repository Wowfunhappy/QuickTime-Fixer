//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSOperation.h"

@class MGMediaComposition, NSDictionary, NSError;

@interface MGPosterImageOperation : NSOperation
{
    NSDictionary *_saveParameters;
    NSError *_error;
    MGMediaComposition *_mediaComposition;
}

@property(copy) NSError *error; // @synthesize error=_error;
- (void)createPosterImage;
- (void)main;
- (void)dealloc;
- (id)initWithParameters:(id)arg1 mediaComposition:(id)arg2;

@end

