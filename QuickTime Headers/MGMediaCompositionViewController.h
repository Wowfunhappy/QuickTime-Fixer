//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "MGDocumentViewController.h"

@class MGMediaClipPreviewProvider, MGMediaComposition, MGMediaCompositionEditController, MGMediaCompositionSelectionController, MGMediaTrackViewController, MGSimpleBinder;

@interface MGMediaCompositionViewController : MGDocumentViewController
{
    MGMediaComposition *_mediaComposition;
    MGMediaCompositionEditController *_editController;
    MGMediaCompositionSelectionController *_selectionController;
    BOOL _showsAdditionalMediaTrack;
    CDStruct_1b6d18a9 _mainMediaTrackDuration;
    CDStruct_1b6d18a9 _currentTimeForLayout;
    CDStruct_1b6d18a9 _duration;
    CDStruct_1b6d18a9 _currentTime;
    BOOL _isPlaying;
    MGMediaClipPreviewProvider *_mediaClipPreviewProvider;
    MGMediaTrackViewController *_mainMediaTrackViewController;
    MGMediaTrackViewController *_additionalMediaTrackViewController;
    BOOL _isInDraggingSourceOperation;
    MGSimpleBinder *_currentTimeBinder;
    MGSimpleBinder *_isPlayingBinder;
    unsigned int _isShowingMediaTracks:1;
    unsigned int _isShowingAlternateMediaItemPreviews:1;
}

+ (BOOL)automaticallyNotifiesObserversOfCurrentTime;
+ (BOOL)automaticallyNotifiesObserversOfCurrentTimeForLayout;
+ (BOOL)automaticallyNotifiesObserversOfMainMediaTrackDuration;
@property(nonatomic, getter=isInDraggingSourceOperation) BOOL inDraggingSourceOperation; // @synthesize inDraggingSourceOperation=_isInDraggingSourceOperation;
@property(readonly, nonatomic) MGMediaTrackViewController *additionalMediaTrackViewController; // @synthesize additionalMediaTrackViewController=_additionalMediaTrackViewController;
@property(readonly, nonatomic) MGMediaTrackViewController *mainMediaTrackViewController; // @synthesize mainMediaTrackViewController=_mainMediaTrackViewController;
@property(retain, nonatomic) MGMediaClipPreviewProvider *mediaClipPreviewProvider; // @synthesize mediaClipPreviewProvider=_mediaClipPreviewProvider;
@property(nonatomic, getter=isPlaying) BOOL playing; // @synthesize playing=_isPlaying;
@property(nonatomic) CDStruct_1b6d18a9 duration; // @synthesize duration=_duration;
@property(retain, nonatomic) MGMediaCompositionSelectionController *selectionController; // @synthesize selectionController=_selectionController;
- (void)invalidateRestorableState;
- (void)restoreStateWithCoder:(id)arg1;
- (void)encodeRestorableStateWithCoder:(id)arg1;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)unbind:(id)arg1;
- (void)bind:(id)arg1 toObject:(id)arg2 withKeyPath:(id)arg3 options:(id)arg4;
- (void)keyDown:(id)arg1;
- (void)toggleAudioTrackShown:(id)arg1;
- (void)selectAll:(id)arg1;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (BOOL)canPerformSelector:(SEL)arg1;
- (double)viewHeightShowingAdditionalMediaTrack:(BOOL)arg1;
- (void)hide;
- (void)show;
@property(nonatomic) CDStruct_1b6d18a9 currentTime;
@property(nonatomic) CDStruct_1b6d18a9 currentTimeForLayout;
@property(nonatomic) CDStruct_1b6d18a9 mainMediaTrackDuration;
@property(nonatomic) BOOL showsAdditionalMediaTrack;
@property(retain, nonatomic) MGMediaCompositionEditController *editController;
@property(retain, nonatomic) MGMediaComposition *mediaComposition;
- (void)close;
- (void)loadView;
- (void)dealloc;
- (id)initWithDocument:(id)arg1 nibName:(id)arg2 bundle:(id)arg3;
- (void)updateCurrentTimeForLayout;
- (id)mediaCompositionView;

@end

