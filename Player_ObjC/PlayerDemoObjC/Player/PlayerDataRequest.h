//
//  PlayerDataRequest.h
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlayerDataRequest;

@protocol PlayerDataRequestDelegate <NSObject>

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest didReceiveData:(NSData *)data;
- (void)playerDataRequest:(PlayerDataRequest *)dataRequest didCompleteWithError:(nullable NSError *)error;

@end

@interface PlayerDataRequest : NSObject

@property (nonatomic, strong) NSString* destinationDirectory;

@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger downloadedLength;
@property (nonatomic, assign) NSInteger contentLength;
@property (nonatomic, strong) NSString* contentType;

@property (nonatomic, weak) id<PlayerDataRequestDelegate> delegate;

- (void)resume:(NSString *)urlString withOffset:(NSInteger)offset;
- (void)cancel:(NSString *)urlString;

@end
