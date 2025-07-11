//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSTextField, QTHUDGroupViewItem;

@interface MGGroupViewTextFieldPairResizer : NSObject
{
    QTHUDGroupViewItem *firstGroupViewItem;
    NSTextField *firstTextField;
    QTHUDGroupViewItem *secondGroupViewItem;
    NSTextField *secondTextField;
}

@property(retain, nonatomic) NSTextField *secondTextField; // @synthesize secondTextField;
@property(retain, nonatomic) QTHUDGroupViewItem *secondGroupViewItem; // @synthesize secondGroupViewItem;
@property(retain, nonatomic) NSTextField *firstTextField; // @synthesize firstTextField;
@property(retain, nonatomic) QTHUDGroupViewItem *firstGroupViewItem; // @synthesize firstGroupViewItem;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)layoutGroupViewItems;
- (void)dealloc;

@end

