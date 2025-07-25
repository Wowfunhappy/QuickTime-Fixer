//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSOperation.h"

@class MGFlickrRESTInterface, NSError, NSMutableData, NSObject<OS_dispatch_queue>, NSObject<OS_dispatch_source>, NSString, NSURL, NSURLRequest, NSURLResponse;

@interface MGFlickrPublishStatusOperation : NSOperation
{
    unsigned int _finished:1;
    unsigned int _executing:1;
    NSError *_error;
    NSObject<OS_dispatch_queue> *_timerQueue;
    NSObject<OS_dispatch_source> *_timer;
    MGFlickrRESTInterface *_flickrInterface;
    NSString *_ticketsString;
    NSURL *_revealURL;
    BOOL _ticketStatusDone;
    NSMutableData *_downloadedData;
    NSURLResponse *_response;
    NSURLRequest *_request;
}

@property(copy, nonatomic) NSURLRequest *request; // @synthesize request=_request;
@property(copy, nonatomic) NSURLResponse *response; // @synthesize response=_response;
@property(copy) NSURL *revealURL; // @synthesize revealURL=_revealURL;
@property(copy) NSString *ticketsString; // @synthesize ticketsString=_ticketsString;
@property(copy) NSError *error; // @synthesize error=_error;
@property(readonly) NSString *localizedStatusMessage;
@property(readonly) float progress;
- (void)cancel;
- (void)handleUploadDidFinish;
- (void)makeTicketStatusRequestedConnection;
- (void)makeVideoStatusRequestedConnection;
- (BOOL)isFinished;
- (BOOL)isExecuting;
- (BOOL)isConcurrent;
- (void)start;
- (void)dealloc;
- (id)initWithFlickrInterface:(id)arg1;
- (id)init;

@end

