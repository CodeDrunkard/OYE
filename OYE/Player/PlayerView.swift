//
//  PlayerView.swift
//  OYE
//
//  Created by JT Ma on 30/09/2017.
//  Copyright © 2017 JiangtaoMa<majt@hiscene.com>. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        makeConstraints()
        preview.player = player.player
        player.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
        makeConstraints()
        preview.player = player.player
        player.delegate = self
    }
    
    func play(url: URL?) {
        guard let url = url else {
            return
        }
        player.playerItem = AVPlayerItem(url: url)
    }
    
    @objc func playOrPause(_ sender: UIButton) {
        if !sender.isSelected {
            pause()
        } else {
            play()
        }
    }
    
    @objc func durationSliderBegan(_ sender: UISlider) {
        pause()
    }
    
    @objc func durationSliderMove(_ sender: UISlider) {
        uiCurrentDurationLabel.text = convert(duration: sender.value * player.duration)
        player.seek(to: Double(sender.value * player.duration), completionHandler: nil)
    }
    
    @objc func durationSliderEnd(_ sender: UISlider) {
        player.seek(to: Double(sender.value * totalDuration)) { finished in
            if finished {
                self.play()
            }
        }
    }
    
    func play() {
        player.play()
        uiPlayButton.isSelected = false
    }
    
    func pause() {
        player.pause()
        uiPlayButton.isSelected = true
    }
    
    // MARK: UI
    
    private let player = Player()
    private let preview = PlayerPreview()
    
    private let uiView = UIView()
    private let uiCurrentDurationLabel = UILabel()
    private let uiDurationLabel = UILabel()
    private let uiDurationSlider = UISlider()
    private let uiDurationProgressView = UIProgressView()
    private let uiPlayButton = UIButton(type: UIButtonType.custom)
    
    private var totalDuration: Float = 0
}

extension PlayerView: PlayerDurationProtocol {
    func playerTotalDuration(duration: Float) {
        totalDuration = duration
        uiDurationLabel.text = convert(duration: duration)
    }
    
    func playerDidLoadedDuration(duration: Float) {
        uiDurationProgressView.setProgress(Float(duration), animated: true)
    }
    
    func playerCurrentDuration(duration: Float) {
        guard totalDuration > 0 else {
            return
        }
        uiCurrentDurationLabel.text = convert(duration: duration)
        uiDurationSlider.value = duration / totalDuration
    }
}

extension PlayerView {
    func convert(duration: Float) -> String {
        let min = Int(duration / 60)
        let sec = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
}

extension PlayerView {
    func setupUI() {
//        uiView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        
        uiCurrentDurationLabel.text = "00:00"
        uiCurrentDurationLabel.textColor = .white
        uiCurrentDurationLabel.textAlignment = .center
        uiCurrentDurationLabel.font = UIFont.systemFont(ofSize: 15)
        uiDurationLabel.text = "00:00"
        uiDurationLabel.textColor = .white
        uiDurationLabel.textAlignment = .center
        uiDurationLabel.font = UIFont.systemFont(ofSize: 15)
        
        uiDurationSlider.maximumValue = 1.0
        uiDurationSlider.minimumValue = 0.0
        uiDurationSlider.value = 0.0
        uiDurationSlider.setThumbImage(UIImage(named: "Player_slider_thumb"), for: .normal)
        uiDurationSlider.maximumTrackTintColor = UIColor.clear
        uiDurationSlider.minimumTrackTintColor = UIColor.green
        uiDurationSlider.addTarget(self, action: #selector(self.durationSliderBegan(_:)), for: .touchDown)
        uiDurationSlider.addTarget(self, action: #selector(self.durationSliderMove(_:)), for: .valueChanged)
        uiDurationSlider.addTarget(self, action: #selector(self.durationSliderEnd(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        uiDurationProgressView.tintColor      = UIColor (red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        uiDurationProgressView.trackTintColor = UIColor (red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        
        uiPlayButton.setImage(UIImage(named: "Player_play"), for: .selected)
        uiPlayButton.setImage(UIImage(named: "Player_pause"), for: .normal)
        uiPlayButton.addTarget(self, action: #selector(self.playOrPause(_:)), for: .touchUpInside)
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
        
        uiView.addSubview(uiPlayButton)
        uiPlayButton.snp.makeConstraints {
            $0.center.equalTo(uiView)
            $0.width.height.equalTo(80)
        }
    }

}
