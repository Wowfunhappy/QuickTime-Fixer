//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGYouTubeUnpublishWindowController;

@interface MGYouTubeAuthenticationSheetController : NSObject
{
    MGYouTubeUnpublishWindowController *_unpublishWindowController;
}

+ (id)sharedAuthenticationSheetController;
- (void)unpublishAuthenticationSheetDidEnd:(id)arg1 returnCode:(long long)arg2 contextInfo:(void *)arg3;
- (void)requestAuthTokenForUserName:(id)arg1 completionHandler:(CDUnknownBlockType)arg2;
- (void)displayAuthenticationSheetWithUserName:(id)arg1;

@end

