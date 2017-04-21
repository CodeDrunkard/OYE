//
//  Player.swift
//  OYE
//
//  Created by JT Ma on 21/04/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

public class Player: UIView {
    
    public var player: AVPlayer? {
        didSet {
            preview.player = player
        }
    }
    
    public var playerItem: AVPlayerItem? {
        didSet {
            player = AVPlayer(playerItem: playerItem)
            player?.play()
        }
    }
    
    enum PlayerItemObserverKey: String {
        case status
        case loadedTimeRanges
        case playbackBufferEmpty
        case playbackLikelyToKeepUp
    }
    
    var duration: Double! {
        didSet {
            let min = Int(duration / 60)
            let sec = Int(duration.truncatingRemainder(dividingBy: 60))
            uiDurationLabel.text = String(format: "%02d:%02d", min, sec)
        }
    }
    
    var didLoadedDuration: Float! {
        didSet {
            uiDurationProgressView.setProgress(didLoadedDuration, animated: true)
        }
    }
    
    // MARK: LifeCycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupUI()
        makeConstraints()
    }
    
    // MARK: UI
    
    private let preview = VideoPreview()
    
    private let uiView = UIView()
    private let uiCurrentDurationLabel = UILabel()
    private let uiDurationLabel = UILabel()
    private let uiDurationSlider = UISlider()
    private let uiDurationProgressView = UIProgressView()
    private let uiPlayButton = UIButton(type: UIButtonType.custom)
    
    func setupUI() {
        uiView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        
        uiCurrentDurationLabel.text = "00:00"
        uiCurrentDurationLabel.textColor = .white
        uiCurrentDurationLabel.textAlignment = .center
        uiCurrentDurationLabel.font = UIFont.systemFont(ofSize: 14)
        uiDurationLabel.text = "00:00"
        uiDurationLabel.textColor = .white
        uiDurationLabel.textAlignment = .center
        uiDurationLabel.font = UIFont.systemFont(ofSize: 14)

        uiDurationSlider.maximumValue = 1.0
        uiDurationSlider.minimumValue = 0.0
        uiDurationSlider.value = 0.0
        uiDurationSlider.setThumbImage(UIImage(named: "Player_slider_thumb"), for: .normal)
        uiDurationSlider.maximumTrackTintColor = UIColor.clear
        
        uiDurationProgressView.tintColor      = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6 )
        uiDurationProgressView.trackTintColor = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3 )
        
        uiPlayButton.setImage(UIImage(named: "Player_play"), for: .normal)
        uiPlayButton.setImage(UIImage(named: "Player_pause"), for: .selected)
        uiPlayButton.addTarget(self, action: #selector(Player.play), for: .touchUpInside)
    }
    
    func makeConstraints() {
        addSubview(preview)
        preview.snp.makeConstraints {
            $0.bottom.right.top.left.equalTo(self)
        }
        
        addSubview(uiView)
        uiView.snp.makeConstraints {
            $0.top.bottom.right.left.equalTo(self)
        }
        
        uiView.addSubview(uiCurrentDurationLabel)
        uiCurrentDurationLabel.snp.makeConstraints {
            $0.left.equalTo(uiView).offset(15)
            $0.bottom.equalTo(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(20)
        }
        
        uiView.addSubview(uiDurationLabel)
        uiDurationLabel.snp.makeConstraints {
            $0.centerY.equalTo(uiCurrentDurationLabel)
            $0.right.equalTo(uiView).offset(-15)
            $0.width.equalTo(uiCurrentDurationLabel)
            $0.height.equalTo(uiCurrentDurationLabel)
        }
        
        uiView.addSubview(uiDurationSlider)
        uiDurationSlider.snp.makeConstraints {
            $0.centerY.equalTo(uiCurrentDurationLabel)
            $0.left.equalTo(uiCurrentDurationLabel.snp.right).offset(10)
            $0.right.equalTo(uiDurationLabel.snp.left).offset(-10)
            $0.height.equalTo(20)
        }
        
        uiView.addSubview(uiDurationProgressView)
        uiDurationProgressView.snp.makeConstraints {
            $0.left.right.equalTo(uiDurationSlider)
            $0.centerY.equalTo(uiDurationSlider).offset(1)
            $0.height.equalTo(2)
        }
        
//        uiView.addSubview(uiBottomMaskView)
//        uiBottomMaskView.snp.makeConstraints {
//            $0.left.bottom.right.equalTo(uiView)
//            $0.height.equalTo(50)
//        }
        
//        uiBottomMaskView.addSubview(uiPlayButton)
//        uiPlayButton.snp.makeConstraints {
//            $0.left.top.equalTo(uiBottomMaskView).offset(5)
//            $0.bottom.equalTo(-5)
//            $0.width.equalTo(40)
//        }
    }
    
    // MARK: Action
    
    func play() {
        print("play")
    }
}
