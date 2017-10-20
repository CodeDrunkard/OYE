//
//  PlayerDataRequest.m
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import "PlayerDataRequest.h"

@interface PlayerDataRequest () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) PlayerModel *playerModel;

@property (nonatomic, assign) NSInteger requestOffset;
@property (nonatomic, assign) NSInteger downloadedLength;
@property (nonatomic, assign) NSInteger contentLength;
@property (nonatomic, strong) NSString *contentType;

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *cacheDirectory;

@property (nonatomic, assign) BOOL isInvalid;

@end

@interface PlayerDataRequest (FileManager)

- (void)createDirectoryAtPath:(NSString *_Nullable)path;
- (BOOL)deleteFileAtPath:(NSString *_Nullable)path;

@end

@implementation PlayerDataRequest

- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.cacheDirectory = cacheDirectory;
        [self createDirectoryAtPath:self.cacheDirectory];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"Player: data request dealloc");
}

- (void)invalidate {
    self.isInvalid = YES;
    [self.session invalidateAndCancel];
//    [self deleteFileAtPath:self.cacheDirectory];
}

- (void)resume:(NSString *)urlString requestOffset:(NSInteger)offset {
    self.requestOffset = offset;
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    
    if (! self.playerModel) {
        self.playerModel = [[PlayerModel alloc] initWithURL:urlString];
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    if (self.playerModel.isDownloading) return;
    
    if (offset >= 0) {
        NSString *range = [NSString stringWithFormat:@"bytes:%zd-", offset];
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
    
    self.playerModel.task = [self.session dataTaskWithRequest:request];
    
    [self.playerModel.task resume];
    self.playerModel.isDownloading = YES;
    
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:url.lastPathComponent];
    self.playerModel.cachePath = cachePath;
    self.playerModel.location = [NSURL fileURLWithPath:cachePath isDirectory:NO];
    
    BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:self.playerModel.cachePath];
    if (isExist) {
        [NSFileManager.defaultManager removeItemAtPath:self.playerModel.cachePath error:nil];
    }
    [NSFileManager.defaultManager createFileAtPath:self.playerModel.cachePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.playerModel.cachePath];
}

- (void)cancel:(NSString *)urlString {
    if (self.playerModel && self.playerModel.isDownloading) {
        self.playerModel.isDownloading = NO;
        [self.playerModel.task cancel];
        self.self.playerModel = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    /*
     NSURLSessionResponseCancel         = 0, 取消 默认
     NSURLSessionResponseAllow          = 1, 接收
     NSURLSessionResponseBecomeDownload = 2, 变成下载任务
     NSURLSessionResponseBecomeStream   = 3, 变成流
     */
    completionHandler(NSURLSessionResponseAllow);
    
    if (self.isInvalid) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *allHeaderFields = (NSDictionary *)[httpResponse allHeaderFields];
    NSInteger length = [[allHeaderFields valueForKey:@"Content-Length"] integerValue];
    NSString *type = [allHeaderFields valueForKey:@"Content-Type"];
    
    self.contentLength = length > 0 ? length : (NSInteger)httpResponse.expectedContentLength;
    self.contentType = type ? type : @"video/mp4";
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (self.isInvalid) {
        return;
    }
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    self.downloadedLength += data.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didReceiveData:receiveDataToURL:)]) {
        [self.delegate playerDataRequest:self didReceiveData:data receiveDataToURL:self.playerModel.location];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (self.isInvalid) {
        return;
    }
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didCompleteWithError:)]) {
            [self.delegate playerDataRequest:self didCompleteWithError:error];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didFinishDownloadingToURL:)]) {
            [self.delegate playerDataRequest:self didFinishDownloadingToURL:self.playerModel.location];
        }
    }
    
    if (self.playerModel) {
        self.playerModel.isDownloading = NO;
        self.self.playerModel = nil;
    }
}

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    if (self.isInvalid) {
        return;
    }
    if (error.code == kCFURLErrorTimedOut) {
        
    } else {
        
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didCompleteWithError:)]) {
        [self.delegate playerDataRequest:self didCompleteWithError:error];
    }
}

@end

@implementation PlayerDataRequest (FileManager)

- (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDirectory, isExist;
    isExist = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (BOOL)deleteFileAtPath:(NSString *)path {
    NSError* error;
    BOOL isDirectory, isExist;
    isExist = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (isExist) {
        BOOL success = [NSFileManager.defaultManager removeItemAtPath:path error:&error];
        if (success) {
            return YES;
        } else {
            NSLog(@"delete directory failure: %@", error.description);
        }
    }
    return NO;
}

@end

/**
 kCFURLErrorBackgroundSessionInUseByAnotherProcess = -996,
 kCFURLErrorBackgroundSessionWasDisconnected = -997,
 kCFURLErrorUnknown = -998,
 kCFURLErrorCancelled = -999,
 kCFURLErrorBadURL = -1000,
 kCFURLErrorTimedOut = -1001,
 kCFURLErrorUnsupportedURL = -1002,
 kCFURLErrorCannotFindHost = -1003,
 kCFURLErrorCannotConnectToHost = -1004,
 kCFURLErrorNetworkConnectionLost = -1005,
 kCFURLErrorDNSLookupFailed = -1006,
 kCFURLErrorHTTPTooManyRedirects = -1007,
 kCFURLErrorResourceUnavailable = -1008,
 kCFURLErrorNotConnectedToInternet = -1009,
 kCFURLErrorRedirectToNonExistentLocation = -1010,
 kCFURLErrorBadServerResponse = -1011,
 kCFURLErrorUserCancelledAuthentication = -1012,
 kCFURLErrorUserAuthenticationRequired = -1013,
 kCFURLErrorZeroByteResource = -1014,
 kCFURLErrorCannotDecodeRawData = -1015,
 kCFURLErrorCannotDecodeContentData = -1016,
 kCFURLErrorCannotParseResponse = -1017,
 kCFURLErrorInternationalRoamingOff = -1018,
 kCFURLErrorCallIsActive = -1019,
 kCFURLErrorDataNotAllowed = -1020,
 kCFURLErrorRequestBodyStreamExhausted = -1021,
 kCFURLErrorAppTransportSecurityRequiresSecureConnection = -1022,
 kCFURLErrorFileDoesNotExist = -1100,
 kCFURLErrorFileIsDirectory = -1101,
 kCFURLErrorNoPermissionsToReadFile = -1102,
 kCFURLErrorDataLengthExceedsMaximum = -1103,
 kCFURLErrorFileOutsideSafeArea = -1104,
 */
