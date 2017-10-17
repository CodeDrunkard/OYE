//
//  ViewController.m
//  PlayerDemoObjC
//
//  Created by JT Ma on 12/10/2017.
//  Copyright © 2017 hiscene<majt@hiscene.com>. All rights reserved.
//

#import "ViewController.h"

#import "Player.h"
#import "PlayerPreview.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerPreview *preview;
@property (nonatomic, strong) Player *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[Player alloc] init];
    self.preview.player = self.player.player;
    
    NSURL *url = [NSURL URLWithString:@"http://video.hiscene.com/20130529_1369795513.mp4"];
    if (url) {
        [self.player playWithURL:url];
        self.player.loop = YES;
    }
}

- (IBAction)play:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"http://video.hiscene.com/20130529_1369795513.mp4"];
    if (url) {
        [self.player playWithURL:url];
        self.player.loop = YES;
    }
}

@end

/*
CredStore - performQuery - Error copying matching creds.  Error=-25300, query={
    class = inet;
    "m_Limit" = "m_LimitAll";
    "r_Attributes" = 1;
    sync = syna;
}
*/
