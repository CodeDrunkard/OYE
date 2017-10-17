//
//  PlayerData.m
//  HiARSDKComponent
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import "PlayerData.h"

@implementation PlayerData

- (instancetype)initWithURL:(NSString *)url  {
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

@end
