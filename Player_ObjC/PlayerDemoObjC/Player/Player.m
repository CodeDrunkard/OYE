//
//  Player.m
//  HiARSDKComponent
//
//  Created by JT Ma on 18/09/2017.
//  Copyright © 2017 MaJiangtao<majt@hiscene.com>. All rights reserved.
//

#import "Player.h"
#import "PlayerAssetLoaderDelegate.h"

/* Asset keys */
NSString * const kPlayableKey        = @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey            = @"rate";
NSString * const kCurrentItemKey    = @"currentItem";

static void *kPlayerStatusObservationContext = &kPlayerStatusObservationContext;
static void *kPlayerRateObservationContext = &kPlayerRateObservationContext;
static void *kPlayerCurrentItemObservationContext = &kPlayerCurrentItemObservationContext;


@interface Player () {
    PlayerAssetLoaderDelegate *assetLoaderDelegate;
}

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *item;
@property (nonatomic, strong) AVPlayerItemVideoOutput *itemOutput;
@property (nonatomic, assign) id itemObserver;

@end

@implementation Player

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.player = [[AVPlayer alloc] init];
}

- (void)dealloc {
    if (self.item) {
        [self.item removeObserver:self forKeyPath:kStatusKey context:kPlayerStatusObservationContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.item];
        [self.item removeOutput:self.itemOutput];
        
        [self.player removeObserver:self forKeyPath:kCurrentItemKey context:kPlayerCurrentItemObservationContext];
        [self.player removeObserver:self forKeyPath:kRateKey context:kPlayerRateObservationContext];
        [self.player removeTimeObserver:self.itemObserver];
    }
}

- (void)playWithURL:(NSURL *)url {
    if (url) {
        AVURLAsset *asset;
        
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *videoPath = [document stringByAppendingPathComponent:url.lastPathComponent];
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
        if (isExist) {
//            asset = [AVURLAsset URLAssetWithURL:url options:nil];
            [NSFileManager.defaultManager removeItemAtPath:videoPath error:nil];
        } else {
        }
        url = [self getSchemeVideoURL:url];
        asset = [AVURLAsset URLAssetWithURL:url options:nil];
        [self configDelegates:asset cacheDirectory:document destDirectory:document];
        
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys  "playable".
         */
        NSArray *requestedKeys = [NSArray arrayWithObjects:kPlayableKey, nil];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler: ^{
             dispatch_async( dispatch_get_main_queue(), ^{
                                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
    }
}

- (void)resume {
    if (!self.isPlaying) {
        self.isPlaying = YES;
        [self.player play];
    }
}

- (void)pause {
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.player pause];
    }
}

- (void)setVolume:(float)volume {
    self.player.volume = volume;
}

- (void)configDelegates:(AVURLAsset *)asset cacheDirectory:(NSString *)cacheDirectory destDirectory:(NSString *)destDirectory {
    self->assetLoaderDelegate = [[PlayerAssetLoaderDelegate alloc] init];
    AVAssetResourceLoader *loader = asset.resourceLoader;
    [loader setDelegate:assetLoaderDelegate queue:dispatch_queue_create("com.hiscene.jt.playerAssetLoader", nil)];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The contents of the resource at the specified URL are not playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.item) {
        [self.item removeObserver:self forKeyPath:kStatusKey];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.item];
        [self.item removeOutput:self.itemOutput];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.item = [AVPlayerItem playerItemWithAsset:asset];
    [self.item addObserver:self
                forKeyPath:kStatusKey
                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                   context:kPlayerStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.item];
    
    self.itemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.item addOutput:self.itemOutput];
    
    if (self.player.currentItem != self.item) {
        [self.player replaceCurrentItemWithPlayerItem:self.item];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kPlayerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kPlayerRateObservationContext];
        
        __weak typeof(self) weakSelf = self;
        self.itemObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf frame];
        }];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    if (self.loop) {
        [self resume];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    
    if (context == kPlayerStatusObservationContext) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        AVPlayerItemStatus status = playerItem.status;
        switch (status) {
            case AVPlayerItemStatusUnknown:{
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusReadyToPlay:{
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                [self resume];
            }
                break;
            case AVPlayerItemStatusFailed:{
                NSLog(@"AVPlayerItemStatusFailed");
                [self pause];
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
            default:
                break;
        }
    } else if (context == kPlayerRateObservationContext) {
        
    } else if (context == kPlayerCurrentItemObservationContext) {
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/*!
 *  Called when an asset fails to prepare for playback for any of
 *  the following reasons:
 *
 *  1) values of asset keys did not load successfully,
 *  2) the asset keys did load successfully, but the asset is not
 *     playable
 *  3) the item did not become ready to play.
 */
- (void)assetFailedToPrepareForPlayback:(NSError *)error {
    /* Display the error. */
    NSLog(@"error: %@, reson: %@", error.localizedDescription, error.localizedFailureReason);
}

- (NSURL *)getSchemeVideoURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}

@end

@implementation Player (FrameOutput)

- (void)frame {
    const CMTime currentTime = self.item.currentTime;
    if ([self.itemOutput hasNewPixelBufferForItemTime:currentTime]) {
        const CVPixelBufferRef pixelBuffer = [self.itemOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
        if (pixelBuffer) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            if([self.delegate respondsToSelector:@selector(playerItemOutput:didOutputPixelBuffer:)]) {
                [self.delegate playerItemOutput:self.itemOutput didOutputPixelBuffer:pixelBuffer];
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CVBufferRelease(pixelBuffer);
        }
    }
}

@end
