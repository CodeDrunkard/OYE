//
//  PlayerPreview.h
//  HiARSDKComponent
//
//  Created by JT Ma on 18/09/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerPreview : UIView

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayer *player;

@end
