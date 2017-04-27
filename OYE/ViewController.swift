//
//  ViewController.swift
//  OYE
//
//  Created by JT Ma on 17/04/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var player: Player!
    @IBOutlet weak var videoAspect: NSLayoutConstraint!
    
    let fullPreview = VideoPreview()
    let minPreview = VideoPreview()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let urlStr = Bundle.main.path(forResource: "14564977406580", ofType: "mp4")!
        let url = URL(fileURLWithPath: urlStr)
        let item = AVPlayerItem(url: url)
        
        player.playerItem = item
        player.play()
        
        minPreview.player = player.player
        
        view.addSubview(minPreview)
        minPreview.snp.makeConstraints {
            $0.right.left.equalTo(self.view)
            $0.top.equalTo(self.view).offset(100)
            $0.height.equalTo(self.view.snp.width).multipliedBy(9.0 / 16.0)
        }
        
        view.addSubview(fullPreview)
        fullPreview.snp.makeConstraints {
            $0.bottom.right.top.left.equalTo(self.view)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.changeStatusBarOrientation),
                                               name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation,
                                               object: nil)
    }
    
    func changeStatusBarOrientation() {
        if !UIApplication.shared.statusBarOrientation.isLandscape {
            fullPreview.player = minPreview.player
            minPreview.player = nil
        } else {
            minPreview.player = fullPreview.player
            fullPreview.player = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationWillChangeStatusBarOrientation,
                                                  object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

