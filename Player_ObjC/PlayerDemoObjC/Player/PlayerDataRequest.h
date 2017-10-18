//
//  PlayerDataRequest.h
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerData.h"

@class PlayerDataRequest;

@protocol PlayerDataRequestDelegate <NSObject>

- (void)playerDataRequest:(PlayerDataRequest *_Nonnull)dataRequest playerData:(PlayerData *_Nullable)model didReceiveData:(NSData *_Nullable)data;
- (void)playerDataRequest:(PlayerDataRequest *_Nonnull)dataRequest playerData:(PlayerData *_Nullable)data didCompleteWithError:(nullable NSError *)error;

@end

@interface PlayerDataRequest : NSObject

@property (nonatomic, readonly) NSInteger startOffset;
@property (nonatomic, readonly) NSInteger downloadedLength;
@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) NSString * _Nullable contentType;

@property (nonatomic, strong) NSString * _Nullable cacheDirectory;

@property (nonatomic, weak) id<PlayerDataRequestDelegate> _Nullable delegate;

- (void)resume:(NSString *_Nullable)urlString withOffset:(NSInteger)offset;
- (void)cancel:(NSString *_Nonnull)urlString;

@end

@interface PlayerDataRequest (FileManager)

- (void)createDirectoryAtPath:(NSString *_Nullable)path;
- (BOOL)deleteFileAtPath:(NSString *_Nullable)path;

@end
