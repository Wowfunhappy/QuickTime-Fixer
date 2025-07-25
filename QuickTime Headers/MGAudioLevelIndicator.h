//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSView.h"

@class CALayer, NSMutableArray;

@interface MGAudioLevelIndicator : NSView
{
    double _value;
    BOOL _bordered;
    CALayer *_barLayer;
    CALayer *_backgroundLayer;
    NSMutableArray *_leftLightLayers;
    NSMutableArray *_rightLightLayers;
}

- (void)updateBorderVisibility;
@property(nonatomic, getter=isBordered) BOOL bordered;
@property(nonatomic) double doubleValue;
- (void)layoutSublayersOfLayer:(id)arg1;
- (void)updateLightLayerVisibility;
- (void)setNumberOfLights:(unsigned long long)arg1 forLightsInLightLayerArray:(id)arg2;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;

@end

