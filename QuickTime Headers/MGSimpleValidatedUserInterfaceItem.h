//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

#import "NSValidatedUserInterfaceItem.h"

@interface MGSimpleValidatedUserInterfaceItem : NSObject <NSValidatedUserInterfaceItem>
{
    SEL _action;
    long long _tag;
}

+ (id)validatedUserInterfaceItemWithAction:(SEL)arg1;
- (long long)tag;
- (SEL)action;
- (id)init;
- (id)initWithAction:(SEL)arg1 tag:(long long)arg2;

@end

