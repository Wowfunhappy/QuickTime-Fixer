//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSTextFieldCell.h"

@class NSURL;

@interface MGURLLinkTextFieldCell : NSTextFieldCell
{
    NSURL *_URL;
    id _unmodifiedObjectValue;
}

- (void)resetCursorRect:(struct CGRect)arg1 inView:(id)arg2;
@property(copy, nonatomic) NSURL *URL;
- (id)setUpFieldEditorAttributes:(id)arg1;
- (void)setObjectValue:(id)arg1;
- (void)dealloc;

@end

