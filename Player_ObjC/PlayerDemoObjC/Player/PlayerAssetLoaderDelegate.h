//
//  PlayerAssetLoaderDelegate.h
//  HiARSDKComponent
//
//  Created by JT Ma on 13/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface PlayerAssetLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCacheDirectory:(NSString *)cacheDirectory destDirectory:(NSString *)destDirectory;

@end
