//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGLanguageAlternate, NSArray, NSDictionary, NSString, QTMovie;

@interface MGMovieLanguageController : NSObject
{
    QTMovie *_movie;
    NSString *_mediaType;
    MGLanguageAlternate *_currentLanguageAlternate;
    NSDictionary *_languageTracksForLanguageAlternates;
    NSDictionary *_excludedLanguageTracksForLanguageAlternates;
    BOOL _languageAlternatesNeedUpdate;
    BOOL _enabled;
    MGLanguageAlternate *_authoredLanguageAlternate;
    MGLanguageAlternate *_systemLanguageAlternate;
}

+ (BOOL)automaticallyNotifiesObserversOfCurrentLanguageAlternate;
@property(copy, nonatomic) MGLanguageAlternate *systemLanguageAlternate; // @synthesize systemLanguageAlternate=_systemLanguageAlternate;
@property(copy, nonatomic) MGLanguageAlternate *authoredLanguageAlternate; // @synthesize authoredLanguageAlternate=_authoredLanguageAlternate;
- (void)update;
- (void)movieEdited:(id)arg1;
@property(retain, nonatomic) QTMovie *movie;
@property(copy, nonatomic) MGLanguageAlternate *currentLanguageAlternate;
@property(readonly, nonatomic) NSArray *excludedLanguageAlternates;
@property(readonly, nonatomic) NSArray *languageAlternates;
@property(nonatomic, getter=isEnabled) BOOL enabled;
- (void)dealloc;
- (id)initWithMediaType:(id)arg1;
- (id)init;

@end

