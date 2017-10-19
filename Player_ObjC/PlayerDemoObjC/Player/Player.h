//
//  Player.h
//  HiARSDKComponent
//
//  Created by JT Ma on 18/09/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol PlayerItemOutputPixelBufferDelegate <NSObject>

- (void)playerItemOutput:(AVPlayerItemOutput *)itemOutput didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface Player : NSObject

@property (nonatomic, readonly) AVPlayer *player;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, weak) id<PlayerItemOutputPixelBufferDelegate> delegate;

- (void)playWithURL:(NSURL *)url;
- (void)resume;
- (void)pause;

@end
