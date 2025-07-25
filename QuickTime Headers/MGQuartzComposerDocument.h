//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "MGDocument.h"

#import "MGInspectionAttributeContainer.h"

@class MGDocumentViewController, NSArray, QCComposition;

@interface MGQuartzComposerDocument : MGDocument <MGInspectionAttributeContainer>
{
    QCComposition *_composition;
    MGDocumentViewController *_mainViewController;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(id)arg1;
+ (id)keyPathsForValuesAffectingInspectionInformation;
+ (id)keyPathsForValuesAffectingInspectionAttributes;
@property(copy) QCComposition *composition; // @synthesize composition=_composition;
- (void)close;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (id)mainViewController;
- (id)displayName;
- (BOOL)readFromData:(id)arg1 ofType:(id)arg2 error:(id *)arg3;
@property(readonly, nonatomic) NSArray *inspectionInformation;
@property(readonly, nonatomic) NSArray *inspectionAttributes;

@end

