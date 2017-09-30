//
//  PlayerPreview.swift
//  OYE
//
//  Created by JT Ma on 30/09/2017.
//  Copyright © 2017 JiangtaoMa<majt@hiscene.com>. All rights reserved.
//

import UIKit
import AVFoundation

public class PlayerPreview: UIView {
    
    public var playerLayer: AVPlayerLayer {
        return (layer as? AVPlayerLayer)!
    }
    
    public var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
