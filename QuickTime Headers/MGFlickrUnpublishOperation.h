//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSOperation.h"

#import "NSURLConnectionDelegate.h"

@class MGFlickrRESTInterface, NSError, NSString;

@interface MGFlickrUnpublishOperation : NSOperation <NSURLConnectionDelegate>
{
    NSError *_error;
    NSString *_authToken;
    NSString *_authTokenSecret;
    NSString *_videoID;
    NSString *_userID;
    MGFlickrRESTInterface *_flickrInterface;
}

@property(copy) NSError *error; // @synthesize error=_error;
@property(readonly) NSString *localizedStatusMessage;
- (void)cancel;
- (void)main;
- (void)dealloc;
- (id)initWithUserID:(id)arg1 videoID:(id)arg2 authorizationToken:(id)arg3 authorizationTokenSecret:(id)arg4;

@end

