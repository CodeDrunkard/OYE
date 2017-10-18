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

@property (nonatomic, strong) NSString *destDirectory;
@property (nonatomic, strong) NSString *cacheDirectory;

@property (nonatomic, strong) PlayerDataRequest *dataRequest;
@property (nonatomic, strong) NSMutableArray *pendingRequests;

@end

@implementation PlayerAssetLoaderDelegate

- (instancetype)init {
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    return [self initWithCacheDirectory:document destDirectory:document];
}

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory destDirectory:(NSString *)destDirectory {
    self = [super init];
    if (self) {
        self.pendingRequests = [NSMutableArray array];
        self.dataRequest = [[PlayerDataRequest alloc] init];
        self.dataRequest.delegate = self;
        self.cacheDirectory = cacheDirectory;
        self.destDirectory = destDirectory;
    }
    return self;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"state: Loading");
    [self.pendingRequests addObject:loadingRequest];
    [self loadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"state: Cancel");
    [self.pendingRequests removeObject:loadingRequest];
}

#pragma mark - PlayerDataRequestDelegate

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
               playerData:(PlayerData *)model
           didReceiveData:(NSData *)data {
    [self internalPendingRequestsWithCachePath:model.cachePath];
}

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
               playerData:(PlayerData *)data
     didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"didCompleteWithError: %@", error.description);
    } else {
        NSLog(@"didComplete");
        if (! [self.cacheDirectory isEqualToString:self.destDirectory]) {
            NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:data.url.lastPathComponent];
            NSString *destPath = [self.destDirectory stringByAppendingPathComponent:data.url.lastPathComponent];
            BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:cachePath toPath:destPath error:nil];
            if (isSuccess) {
                NSLog(@"rename success");
            } else {
                NSLog(@"rename fail");
            }
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
    
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    NSURL *url = actualURLComponents.URL;
    [self.dataRequest resume:url.absoluteString withOffset:0];
}

- (void)cancelRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    NSURL *url = actualURLComponents.URL;
    [self.dataRequest cancel:url.absoluteString];
}

- (void)internalPendingRequestsWithCachePath:(NSString *)cachePath {
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        @autoreleasepool {
            if (! loadingRequest.isFinished) {
                [self fillInContentInformation:loadingRequest.contentInformationRequest];
                BOOL didRespondFinished = [self respondWithDataForRequest:loadingRequest cachePath:cachePath];
                if (didRespondFinished) {
                    [requestsCompleted addObject:loadingRequest];
                }
            }
        }
    }
    if (requestsCompleted.count > 0) {
        NSLog(@"state: Finished");
        
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

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingRequest *)loadingRequest cachePath:(NSString *)cachePath {
    NSUInteger cacheLength = self.dataRequest.downloadedLength;
    NSUInteger requestedOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - 0);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    NSFileHandle  *handle = [NSFileHandle fileHandleForReadingAtPath:cachePath];
    [handle seekToFileOffset:requestedOffset];
    NSData *tempVideoData = [handle readDataOfLength:respondLength];
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


