//
//  PlayerModel.h
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayerModel : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSString *cachePath;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, assign) BOOL isDownloading;

@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double totalSize;
@property (nonatomic, assign) double speed;

- (instancetype)initWithURL:(NSString *)url;

@end
