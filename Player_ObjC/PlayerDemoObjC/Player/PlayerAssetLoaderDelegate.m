//
//  PlayerAssetLoaderDelegate.m
//  HiARSDKComponent
//
//  Created by JT Ma on 13/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "PlayerAssetLoaderDelegate.h"
#import "PlayerDataRequest.h"

@interface PlayerAssetLoaderDelegate () <PlayerDataRequestDelegate>

@property (nonatomic, strong) PlayerDataRequest *dataRequest;
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, strong) NSString *videoPath;

@end

@implementation PlayerAssetLoaderDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pendingRequests = [NSMutableArray array];
        self.dataRequest = [[PlayerDataRequest alloc] init];
        self.dataRequest.delegate = self;
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        self.dataRequest.destinationDirectory = document;
        
        self.videoPath = [document stringByAppendingPathComponent:@"temp.mp4"];
    }
    return self;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests addObject:loadingRequest];
    [self loadingRequest:loadingRequest];
    NSLog(@"state: PlayerAssetLoaderStateLoading");
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests removeObject:loadingRequest];
}

#pragma mark - PlayerDataRequestDelegate

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
           didReceiveData:(NSData *)data {
    [self internalPendingRequests];
}

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
     didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"didCompleteWithError: %@", error.description);
    } else {
        NSLog(@"didComplete");
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *movePath =  [document stringByAppendingPathComponent:@"保存数据.mp4"];
        BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:self.videoPath toPath:movePath error:nil];
        if (isSuccess) {
            NSLog(@"rename success");
        } else {
            NSLog(@"rename fail");
        }
    }
}

#pragma mark - Private

- (void)loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    NSUInteger startOffset = (NSUInteger)dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0) {
        startOffset = (NSUInteger)dataRequest.currentOffset;
    }
    startOffset = MAX(0, startOffset);
    
    NSURLComponents* actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    NSURL* url = actualURLComponents.URL;
    [self.dataRequest resume:url.absoluteString withOffset:0];
}

- (void)internalPendingRequests{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        @autoreleasepool {
            if (! loadingRequest.isFinished) {
                [self fillInContentInformation:loadingRequest.contentInformationRequest];
                BOOL didRespondFinished = [self respondWithDataForRequest:loadingRequest];
                if (didRespondFinished) {
                    [requestsCompleted addObject:loadingRequest];
                }
            }
        }
    }
    if (requestsCompleted.count > 0) {
        [self.pendingRequests removeObjectsInArray:[requestsCompleted copy]];
    }
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest {
    NSString *cType = self.dataRequest.contentType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(cType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.dataRequest.contentLength;
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSUInteger cacheLength = self.dataRequest.downloadedLength;
    NSUInteger requestedOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - 0);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:self.videoPath];
    [handle seekToFileOffset:requestedOffset];
    NSData* tempVideoData = [handle readDataOfLength:respondLength];
    [loadingRequest.dataRequest respondWithData:tempVideoData];
    
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        NSLog(@"finishLoading");
        return YES;
    }
    return NO;
}

@end

