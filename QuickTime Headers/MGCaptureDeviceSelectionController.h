//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class AVCaptureDevice, AVCaptureSession, NSMutableSet, NSSet, NSString;

@interface MGCaptureDeviceSelectionController : NSObject
{
    AVCaptureSession *_captureSession;
    NSMutableSet *_ownedDeviceInputs;
    struct __CFDictionary *_videoDevicesWithErrors;
    struct __CFDictionary *_audioDevicesWithErrors;
    NSMutableSet *_inUseDevices;
    NSMutableSet *_disconnectedDeviceUniqueIDs;
    NSSet *_connectedVideoDevices;
    NSSet *_connectedAudioDevices;
    NSString *_autosaveName;
}

+ (id)_autosavePropertyListUserDefaultsKeyForAutosaveName:(id)arg1;
+ (id)keyPathsForValuesAffectingAudioDevice;
+ (BOOL)automaticallyNotifiesObserversOfAudioDevice;
+ (id)keyPathsForValuesAffectingVideoDevice;
+ (BOOL)automaticallyNotifiesObserversOfVideoDevice;
+ (id)keyPathsForValuesAffectingAvailableAudioDevices;
+ (id)keyPathsForValuesAffectingAvailableVideoDevices;
@property(readonly, nonatomic) AVCaptureSession *captureSession; // @synthesize captureSession=_captureSession;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)_stopAutosavingDevice:(id)arg1;
- (void)_startAutosavingDevice:(id)arg1;
- (void)_updateAutosaveInfoInUserDefaultsForDevice:(id)arg1;
- (id)setVideoDeviceUsingAutosaveName:(id)arg1 passingTest:(CDUnknownBlockType)arg2;
- (id)setAudioDeviceUsingAutosaveName:(id)arg1 passingTest:(CDUnknownBlockType)arg2;
- (id)addVideoDevicesUsingAutosaveName:(id)arg1 passingTest:(CDUnknownBlockType)arg2;
- (id)addAudioDevicesUsingAutosaveName:(id)arg1 passingTest:(CDUnknownBlockType)arg2;
- (id)addDevicesWithMediaType:(id)arg1 usingAutosaveName:(id)arg2 passingTest:(CDUnknownBlockType)arg3;
- (id)_autosavePropertyListUserDefaultsKey;
@property(copy, nonatomic) NSString *autosaveName;
- (BOOL)_attemptToReopenAndAddDevice:(id)arg1 error:(id *)arg2;
- (void)_clearErrorForDevice:(id)arg1 mediaType:(id)arg2;
- (void)_handleError:(id)arg1 forDevice:(id)arg2 mediaType:(id)arg3;
- (id)errorForDevice:(id)arg1;
@property(readonly, nonatomic) BOOL hasDevicesWithErrors;
@property(retain, nonatomic) AVCaptureDevice *audioDevice;
@property(retain, nonatomic) AVCaptureDevice *videoDevice;
- (void)removeAudioDevicesObject:(id)arg1;
- (void)addAudioDevicesObject:(id)arg1;
- (id)audioDevices;
- (void)removeVideoDevicesObject:(id)arg1;
- (void)addVideoDevicesObject:(id)arg1;
- (id)videoDevices;
- (void)closeAndRemoveDevice:(id)arg1 forMediaType:(id)arg2 excludingMediaType:(id)arg3;
- (BOOL)openAndAddDevice:(id)arg1 forMediaType:(id)arg2 excludingMediaType:(id)arg3 error:(id *)arg4;
- (id)addedDevicesWithDeviceInputPortMediaType:(id)arg1;
@property(readonly, nonatomic) NSSet *availableAudioDevices;
@property(readonly, nonatomic) NSSet *availableVideoDevices;
- (void)devicesDidChange:(id)arg1;
- (void)_refreshDevices;
- (void)dealloc;
- (id)initWithCaptureSession:(id)arg1;

@end

