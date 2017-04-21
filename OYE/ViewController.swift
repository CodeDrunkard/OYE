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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let urlStr = Bundle.main.path(forResource: "14564977406580", ofType: "mp4")!
        let url = URL(fileURLWithPath: urlStr)
        let item = AVPlayerItem(url: url)
        
        self.player.playerItem = item
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

