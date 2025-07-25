//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSCountedSet, NSMapTable;

@interface MGMediaClipAssetCache : NSObject
{
    NSMapTable *_assetsForMediaClips;
    NSCountedSet *_reusableAssetURLs;
    NSMapTable *_reusableAssets;
}

- (id)reusableAssetForMediaClip:(id)arg1;
- (void)removeAssetForMediaClip:(id)arg1;
- (void)setAsset:(id)arg1 forMediaClip:(id)arg2;
- (id)assetForMediaClip:(id)arg1;
- (void)dealloc;
- (id)init;

@end

