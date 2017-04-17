//
//  VideoPreviewLayer.swift
//  OYE
//
//  Created by JT Ma on 17/04/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

import UIKit
import AVFoundation

public class VideoPreview: UIView {
    
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
