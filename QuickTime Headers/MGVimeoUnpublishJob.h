//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "MGJob.h"

@class MGVimeoUnpublishOperation, NSError, NSString, NSURL;

@interface MGVimeoUnpublishJob : MGJob
{
    MGVimeoUnpublishOperation *_unpublishOperation;
    NSString *_name;
    NSString *_ID;
    NSURL *_resultURL;
    BOOL _progressIndeterminate;
    NSString *_runningStatusString;
    NSError *_error;
    id _delegate;
}

@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_ID;
@property(copy, nonatomic) NSURL *resultURL; // @synthesize resultURL=_resultURL;
@property(copy, nonatomic) NSString *runningStatusString; // @synthesize runningStatusString=_runningStatusString;
@property(copy, nonatomic) NSError *error; // @synthesize error=_error;
@property(copy, nonatomic) NSString *name; // @synthesize name=_name;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (id)operations;
- (id)finishedStatusString;
- (void)dealloc;
- (id)initWithUserID:(id)arg1 videoID:(id)arg2 authorizationToken:(id)arg3 authorizationTokenSecret:(id)arg4 resultURL:(id)arg5;

@end

