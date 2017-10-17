//
//  PlayerDataRequest.m
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import "PlayerDataRequest.h"
#import "PlayerData.h"

@interface PlayerDataRequest () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, strong) NSMutableDictionary<NSString*, PlayerData*>* activeDownloads;

@property (nonatomic, strong) NSFileHandle* fileHandle;
@property (nonatomic, strong) NSString* videoTempPath;

@end

@implementation PlayerDataRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.activeDownloads = [NSMutableDictionary dictionary];
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        self.videoTempPath = [document stringByAppendingPathComponent:@"temp.mp4"];
        BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:self.videoTempPath];
        if (isExist) {
            [NSFileManager.defaultManager removeItemAtPath:self.videoTempPath error:nil];
        }
        [NSFileManager.defaultManager createFileAtPath:self.videoTempPath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.videoTempPath];
    }
    return self;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
}

- (void)resume:(NSString *)urlString withOffset:(NSInteger)offset {
    self.startOffset = offset;
    
    NSURL* url = [NSURL URLWithString:urlString];
    if (!url) return;
    
    PlayerData* data = self.activeDownloads[urlString];
    if (! data) {
        data = [[PlayerData alloc] initWithURL:urlString];
        self.activeDownloads[urlString] = data;
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    NSLog(@"---data.isDownloading: %d", (int)data.isDownloading);
    if (data.isDownloading) return;
    
    if (offset >= 0) {
        NSString *range = [NSString stringWithFormat:@"bytes:%zd-", offset];
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
    
    data.task = [self.session dataTaskWithRequest:request];
    
    [data.task resume];
    data.isDownloading = YES;
}

- (void)cancel:(NSString *)urlString {
    PlayerData* data = self.activeDownloads[urlString];
    if (data) {
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
    NSString* type = [allHeaderFields valueForKey:@"Content-Type"];
    
    self.contentLength = MAX(length, (NSInteger)httpResponse.expectedContentLength);
    self.contentType = type ? type : @"";
    
    NSLog(@"didReceiveResponse: -length = %ld, -type = %@", (long)self.contentLength, self.contentType);
    
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
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    self.downloadedLength += data.length;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didReceiveData:)]) {
            [self.delegate playerDataRequest:self didReceiveData:data];
        }
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDataRequest:didCompleteWithError:)]) {
        [self.delegate playerDataRequest:self didCompleteWithError:error];
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
    NSLog(@"didBecomeInvalidWithError: %@", error.description);
}

@end
