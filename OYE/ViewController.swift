//
//  ViewController.swift
//  OYE
//
//  Created by JT Ma on 30/09/2017.
//  Copyright © 2017 JiangtaoMa<majt@hiscene.com>. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let urlStr = Bundle.main.path(forResource: "TheOscars", ofType: "mp4")
        let url = URL(fileURLWithPath: urlStr ?? "http://video.hiscene.com/20130529_1369795513.mp4")
        playerView.play(url: url)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

