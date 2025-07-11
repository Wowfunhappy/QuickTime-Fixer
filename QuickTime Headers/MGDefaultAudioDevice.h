//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSObject<OS_dispatch_queue>;

@interface MGDefaultAudioDevice : NSObject
{
    NSObject<OS_dispatch_queue> *_audioDeviceQueue;
    void *_deviceModeSavedStateToken;
    CDUnknownBlockType _listenerBlock;
    BOOL _moviePlaybackModeEnabled;
    unsigned int _audioDeviceID;
}

+ (id)defaultAudioDevice;
+ (void)initialize;
@property unsigned int audioDeviceID; // @synthesize audioDeviceID=_audioDeviceID;
- (void)exitMovieMode;
- (void)enterMovieMode;
- (void)dealloc;
- (id)initWithAudioDeviceID:(unsigned int)arg1;

@end

