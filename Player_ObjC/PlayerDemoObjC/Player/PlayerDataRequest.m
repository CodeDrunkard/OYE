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
@property (nonatomic, strong) NSMutableDictionary<NSString *, PlayerData *> *activeDownloads;

@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger downloadedLength;
@property (nonatomic, assign) NSInteger contentLength;
@property (nonatomic, strong) NSString *contentType;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation PlayerDataRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.activeDownloads = [NSMutableDictionary dictionary];
        NSString* cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        self.cacheDirectory = [cachesDirectory stringByAppendingPathComponent:@"videoTemp"];
        [self createDirectoryAtPath:self.cacheDirectory];
    }
    return self;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
    [self deleteFileAtPath:self.cacheDirectory];
}

- (void)resume:(NSString *)urlString withOffset:(NSInteger)offset {
    self.startOffset = offset;
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    
    PlayerData *data = self.activeDownloads[urlString];
    if (! data) {
        data = [[PlayerData alloc] initWithURL:urlString];
        self.activeDownloads[urlString] = data;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    if (data.isDownloading) return;
    
    if (offset >= 0) {
        NSString *range = [NSString stringWithFormat:@"bytes:%zd-", offset];
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
    
    data.task = [self.session dataTaskWithRequest:request];
    
    [data.task resume];
    data.isDownloading = YES;
    
    data.cachePath = [self.cacheDirectory stringByAppendingPathComponent:url.lastPathComponent];
    BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:data.cachePath];
    if (isExist) {
        [NSFileManager.defaultManager removeItemAtPath:data.cachePath error:nil];
    }
    [NSFileManager.defaultManager createFileAtPath:data.cachePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:data.cachePath];
}

- (void)cancel:(NSString *)urlString {
    PlayerData *data = self.activeDownloads[urlString];
    if (data && data.isDownloading) {
        data.isDownloading = NO;
        [data.task cancel];
        self.activeDownloads[urlString] = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *allHeaderFields = (NSDictionary *)[httpResponse allHeaderFields];
    NSInteger length = [[allHeaderFields valueForKey:@"Content-Length"] integerValue];
    NSString *type = [allHeaderFields valueForKey:@"Content-Type"];
    
    self.contentLength = MAX(length, (NSInteger)httpResponse.expectedContentLength);
    self.contentType = type ? type : @"video/mp4";
    
    /*
     NSURLSessionResponseCancel         = 0, 取消 默认
     NSURLSessionResponseAllow          = 1, 接收
     NSURLSessionResponseBecomeDownload = 2, 变成下载任务
     NSURLSessionResponseBecomeStream   = 3, 变成流
     */
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSString* urlString = dataTask.originalRequest.URL.absoluteString;
    PlayerData *model = self.activeDownloads[urlString];
    
    self.downloadedLength += data.length;
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:playerData:didReceiveData:)]) {
            [self.delegate playerDataRequest:self playerData:model didReceiveData:data];
        }
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSString* urlString = task.originalRequest.URL.absoluteString;
    PlayerData *data = self.activeDownloads[urlString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:playerData:didCompleteWithError:)]) {
        [self.delegate playerDataRequest:self playerData:data didCompleteWithError:error];
    }
}

/**
 -1001: 请求超时
 -1002: URL错误
 -1003: 找不到服务器
 -1004: 服务器内部错误
 -1005: 网络中断
 -1009: 无网络连接
 */
- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"PlayerDataRequest is invalid with error: %@", error.description);
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
