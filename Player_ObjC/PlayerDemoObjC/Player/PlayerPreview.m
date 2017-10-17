//
//  PlayerPreview.m
//  HiARSDKComponent
//
//  Created by JT Ma on 18/09/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import "PlayerPreview.h"

@implementation PlayerPreview

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    if (!self.playerLayer.player) {
        self.playerLayer.player = player;
    }
}

@end
