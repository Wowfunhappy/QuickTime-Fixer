//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "MGJob.h"

@class MGExportOperation, NSError, NSString;

@interface MGiTunesPublishJob : MGJob
{
    MGExportOperation *_exportOperation;
    BOOL _progressIndeterminate;
    float _progress;
    NSString *_name;
    NSString *_runningStatusString;
    NSError *_error;
}

+ (id)iTunesPublishJobWithMediaComposition:(id)arg1 exportParameters:(id)arg2;
@property(copy, nonatomic) NSError *error; // @synthesize error=_error;
@property(copy, nonatomic) NSString *runningStatusString; // @synthesize runningStatusString=_runningStatusString;
@property(nonatomic, getter=isProgressIndeterminate) BOOL progressIndeterminate; // @synthesize progressIndeterminate=_progressIndeterminate;
@property(nonatomic) float progress; // @synthesize progress=_progress;
@property(copy, nonatomic) NSString *name; // @synthesize name=_name;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (id)operations;
- (void)dealloc;
- (id)initWithMediaComposition:(id)arg1 exportParameters:(id)arg2;

@end

