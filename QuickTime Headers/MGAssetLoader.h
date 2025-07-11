//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class AVAsset, MGAssetValidator, NSArray, NSDictionary, NSError, NSObject<OS_dispatch_queue>, NSURL;

@interface MGAssetLoader : NSObject
{
    NSURL *_URL;
    NSDictionary *_assetOptions;
    NSArray *_keysForInitialAssetValuesToLoad;
    NSObject<OS_dispatch_queue> *_completionQueue;
    CDUnknownBlockType _completionBlock;
    AVAsset *_asset;
    NSError *_error;
    MGAssetValidator *_validator;
    NSURL *_loadingURL;
    AVAsset *_loadingAsset;
    NSObject<OS_dispatch_queue> *_loaderQueue;
    unsigned int _didCallCompletionBlock:1;
    unsigned int _cancelled:1;
    unsigned int _visiblyCancelled:1;
}

+ (id)synchronouslyLoadedAssetWithURL:(id)arg1 assetOptions:(id)arg2 keysForInitialAssetValuesToLoad:(id)arg3 error:(id *)arg4;
+ (id)presentableErrorForLoadingURL:(id)arg1 code:(long long)arg2 userInfo:(id)arg3;
+ (void)initialize;
@property(readonly, nonatomic) NSError *error; // @synthesize error=_error;
@property(readonly, nonatomic) AVAsset *asset; // @synthesize asset=_asset;
@property(readonly, nonatomic) NSURL *URL; // @synthesize URL=_URL;
@property(readonly, nonatomic, getter=isCancelled) BOOL cancelled;
- (void)cancelLoading;
- (void)startLoadingWithCompletionQueue:(id)arg1 completionBlock:(CDUnknownBlockType)arg2;
- (void)_preflightAsset;
- (void)_validateAsset;
- (void)_loadAsset;
- (void)loadingDidSucceed;
- (void)loadingDidFailWithError:(id)arg1;
- (void)tearDownLoading;
- (void)dealloc;
- (id)initWithURL:(id)arg1 assetOptions:(id)arg2 keysForInitialAssetValuesToLoad:(id)arg3;

@end

