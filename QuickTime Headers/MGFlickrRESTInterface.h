//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

#import "NSURLConnectionDelegate.h"
#import "NSXMLParserDelegate.h"

@class NSDictionary, NSError, NSMutableData, NSMutableString, NSRunLoop, NSString, NSURL, NSURLConnection, NSXMLParser;

@interface MGFlickrRESTInterface : NSObject <NSXMLParserDelegate, NSURLConnectionDelegate>
{
    NSString *_token;
    NSString *_tokenSecret;
    NSDictionary *_accountInfo;
    NSDictionary *_ticketsStatusDictionary;
    NSURL *_videoURL;
    NSError *_parseError;
    NSMutableString *_currentStringValue;
    int _parseState;
    BOOL _videoReady;
    BOOL _requestInProgress;
    BOOL _shouldStop;
    NSRunLoop *_connectionRunLoop;
    NSURLConnection *_connection;
    NSMutableData *_connectionData;
    NSError *_error;
    NSXMLParser *_parser;
}

+ (id)signatureForCall:(id)arg1;
+ (id)escapedStringForString:(id)arg1;
@property(copy, nonatomic) NSString *tokenSecret; // @synthesize tokenSecret=_tokenSecret;
@property(copy, nonatomic) NSString *token; // @synthesize token=_token;
@property(copy, nonatomic) NSError *error; // @synthesize error=_error;
@property(nonatomic) BOOL requestInProgress; // @synthesize requestInProgress=_requestInProgress;
@property(nonatomic) BOOL videoReady; // @synthesize videoReady=_videoReady;
@property int parseState; // @synthesize parseState=_parseState;
@property(copy, nonatomic) NSDictionary *accountInfo; // @synthesize accountInfo=_accountInfo;
@property(copy, nonatomic) NSDictionary *ticketsStatusDictionary; // @synthesize ticketsStatusDictionary=_ticketsStatusDictionary;
@property(copy, nonatomic) NSError *parseError; // @synthesize parseError=_parseError;
- (void)connection:(id)arg1 didFailWithError:(id)arg2;
- (void)connectionDidFinishLoading:(id)arg1;
- (void)connection:(id)arg1 didReceiveData:(id)arg2;
- (void)connection:(id)arg1 didReceiveResponse:(id)arg2;
- (void)parser:(id)arg1 parseErrorOccurred:(id)arg2;
- (void)parserDidEndDocument:(id)arg1;
- (void)parser:(id)arg1 didEndElement:(id)arg2 namespaceURI:(id)arg3 qualifiedName:(id)arg4;
- (void)parser:(id)arg1 foundCharacters:(id)arg2;
- (void)parser:(id)arg1 didStartElement:(id)arg2 namespaceURI:(id)arg3 qualifiedName:(id)arg4 attributes:(id)arg5;
- (BOOL)parseXMLData:(id)arg1 error:(id *)arg2;
- (void)cancelRequest;
- (BOOL)sendGETRequestWithMethodName:(id)arg1 optionsDictionary:(id)arg2 requiresAuth:(BOOL)arg3 requiresSignature:(BOOL)arg4 error:(id *)arg5;
- (id)oauthParameters;
- (id)signatureForCommand:(id)arg1 baseURLString:(id)arg2 parameters:(id)arg3;
- (id)deletePhotoID:(id)arg1;
- (id)setWritePermissionsForPhotoID:(id)arg1 isPrivate:(BOOL)arg2;
- (id)getInfoForPhotoID:(id)arg1;
- (id)checkTicketsStatus:(id)arg1;
- (void)getUploadLimitsWithHandler:(CDUnknownBlockType)arg1;
- (id)testAuthentication;
- (id)checkToken;
- (id)userName;
- (id)videoURL;
- (void)setVideoURL:(id)arg1;
- (void)dealloc;
- (void)verifyUserPermissionsAndQuotaWithCompletionBlock:(CDUnknownBlockType)arg1;
- (BOOL)authorizeAndValidateApplication:(id *)arg1;
- (id)initWithToken:(id)arg1 secret:(id)arg2;
- (id)init;

@end

