//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@interface QTPerfTaskTime : NSObject
{
    struct _QTTestTime *_testTime;
    BOOL _collecting;
}

- (id)values;
- (void)stop;
- (void)startFromEnvVar:(const char *)arg1;
- (void)start;
- (void)dealloc;
- (id)init;

@end

