//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

#import "MGScreenSelectorOverlayViewDelegate.h"

@class NSDictionary, NSMutableArray, NSOperationQueue, NSString;

@interface MGScreenSelector : NSObject <MGScreenSelectorOverlayViewDelegate>
{
    NSDictionary *_windowsForDisplayIDs;
    id <MGScreenSelectorDelegate> _delegate;
    NSString *_selectionString;
    NSString *_confirmationString;
    struct CGSize _minimumSelectionSize;
    struct CGRect _selectionRect;
    unsigned int _selectionLocked:1;
    unsigned int _isRequestingSelection:1;
    NSOperationQueue *_hideShowQueue;
    NSMutableArray *_observerTokens;
}

+ (long long)screenSelectorWindowLevel;
@property(copy) NSMutableArray *observerTokens; // @synthesize observerTokens=_observerTokens;
@property(retain) NSOperationQueue *hideShowQueue; // @synthesize hideShowQueue=_hideShowQueue;
@property(readonly, nonatomic) id <MGScreenSelectorDelegate> delegate; // @synthesize delegate=_delegate;
@property(copy, nonatomic) NSDictionary *windowsForDisplayIDs; // @synthesize windowsForDisplayIDs=_windowsForDisplayIDs;
- (void)stopRequestingSelection;
- (void)startRequestingSelectionWithDelegate:(id)arg1;
- (void)reloadOverlays;
- (void)overlayViewDidConfirm:(id)arg1;
- (void)overlayViewDidCancel:(id)arg1;
- (void)overlayViewDidActivate:(id)arg1;
@property(nonatomic, getter=isSelectionLocked) BOOL selectionLocked;
@property(nonatomic) struct CGSize minimumSelectionSize;
@property(copy, nonatomic) NSString *confirmationString;
@property(copy, nonatomic) NSString *selectionString;
- (void)enumerateOverlayViewsUsingBlock:(CDUnknownBlockType)arg1;
- (void)applicationDidChangeScreenParameters:(id)arg1;
- (void)dealloc;
- (id)init;

@end

