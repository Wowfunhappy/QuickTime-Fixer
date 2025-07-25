//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class MGAudioAmplitudeExtractionSession, MGAudioSilenceBoundaryLocator, NSArray, NSObject<OS_dispatch_queue>, NSSet;

@interface MGAudioAnalyzer : NSObject
{
    MGAudioAmplitudeExtractionSession *_audioAmplitudeExtractionSession;
    NSArray *_boundaryTimes;
    NSSet *_inactiveTimeRanges;
    NSObject<OS_dispatch_queue> *_amplitudeSampleAnalysisDispatchQueue;
    MGAudioSilenceBoundaryLocator *_audioSilenceBoundaryLocator;
    unsigned long long _numberOfPendingAmplitudeSamples;
    unsigned long long _numberOfAnalyzedAmplitudeSamples;
    int _didFinishAmplitudeSampleAnalysis;
    BOOL _analysisFinished;
}

@property(readonly, nonatomic) NSSet *inactiveTimeRanges; // @synthesize inactiveTimeRanges=_inactiveTimeRanges;
@property(readonly, nonatomic) NSArray *boundaryTimes; // @synthesize boundaryTimes=_boundaryTimes;
@property(readonly, nonatomic, getter=isAnalysisFinished) BOOL analysisFinished; // @synthesize analysisFinished=_analysisFinished;
@property(readonly, nonatomic) MGAudioAmplitudeExtractionSession *audioAmplitudeExtractionSession; // @synthesize audioAmplitudeExtractionSession=_audioAmplitudeExtractionSession;
- (CDStruct_e83c9415)totalActivityTimeRangeInRange:(CDStruct_e83c9415)arg1;
- (void)finishAudioAnalysis;
- (void)updateAudioAnalysis;
- (void)audioExtractionSessionDidFinishExtraction:(id)arg1;
- (void)audioAmplitudeSamplesDidBecomeAvailable:(id)arg1;
- (void)dealloc;
- (id)init;
- (id)initWithAudioAmplitudeExtractionSession:(id)arg1;

@end

