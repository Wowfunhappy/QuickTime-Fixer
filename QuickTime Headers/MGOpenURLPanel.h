//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSPanel.h"

@class NSArray, NSButton, NSComboBox, NSSet, NSString, NSURL;

@interface MGOpenURLPanel : NSPanel
{
    NSComboBox *_URLField;
    NSButton *_OKButton;
    NSString *_URLString;
    NSArray *_recentURLs;
    NSSet *_allowedURLSchemes;
    NSString *_defaultURLScheme;
}

+ (id)openURLPanel;
@property(copy, nonatomic) NSString *defaultURLScheme; // @synthesize defaultURLScheme=_defaultURLScheme;
@property(copy, nonatomic) NSSet *allowedURLSchemes; // @synthesize allowedURLSchemes=_allowedURLSchemes;
@property(copy, nonatomic) NSArray *recentURLs; // @synthesize recentURLs=_recentURLs;
@property(copy, nonatomic) NSString *URLString; // @synthesize URLString=_URLString;
- (long long)runModal;
- (void)cancel:(id)arg1;
- (void)ok:(id)arg1;
@property(readonly, nonatomic) NSURL *URL;
- (void)close;
- (void)dealloc;
- (id)initWithContentRect:(struct CGRect)arg1 styleMask:(unsigned long long)arg2 backing:(unsigned long long)arg3 defer:(BOOL)arg4;

@end

