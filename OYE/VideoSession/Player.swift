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
            playerItem?.addObserver(self, forKeyPath: PlayerItemObserverKey.status.rawValue, options:NSKeyValueObservingOptions.new, context: nil)
            playerItem?.addObserver(self, forKeyPath: PlayerItemObserverKey.loadedTimeRanges.rawValue, options:NSKeyValueObservingOptions.new, context: nil)
            
            player = AVPlayer(playerItem: playerItem)
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
            uiDurationLabel.text = convert(duration: Float(duration))
        }
    }
    
    var didLoadedDuration: Float! {
        didSet {
            uiDurationProgressView.setProgress(didLoadedDuration, animated: true)
        }
    }
    
    var currentDuration: Float! {
        didSet {
            uiCurrentDurationLabel.text = convert(duration: currentDuration)
            uiDurationSlider.value = currentDuration / Float(duration!)
        }
    }
    
    var timer: Timer?
    
    // MARK: LifeCycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        addApplicationNotification()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupUI()
        makeConstraints()
        addApplicationNotification()
    }
    
    deinit {
        removeApplicationNotification()
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
        
        uiPlayButton.setImage(UIImage(named: "Player_play"), for: .normal)
        uiPlayButton.setImage(UIImage(named: "Player_pause"), for: .selected)
        uiPlayButton.addTarget(self, action: #selector(self.play), for: .touchUpInside)
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
        setupTimer()
        player?.play()
//        uiView.fadeOut()
    }
    
    func pause() {
        timer?.invalidate()
        player?.pause()
    }
    
    func seek(to seconds: TimeInterval, completionHandler: ((Bool) -> Swift.Void)?) {
        let draggedTime = CMTimeMake(Int64(seconds), 1)
        player?.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { finished in
            completionHandler?(finished)
        }
    }
    
    func durationSliderBegan(_ sender: UISlider) {
        pause()
    }
    
    func durationSliderMove(_ sender: UISlider) {
        uiCurrentDurationLabel.text = convert(duration: sender.value * Float(duration))
        seek(to: Double(sender.value) * duration, completionHandler: nil)
    }
    
    func durationSliderEnd(_ sender: UISlider) {
        seek(to: Double(sender.value) * duration) { finished in
            if finished {
                self.setupTimer()
                self.play()
            }
        }
    }
}

extension Player {
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = player, let item = object as? AVPlayerItem, let key = keyPath else {
            return
        }
        switch key {
        case PlayerItemObserverKey.status.rawValue:
            switch player.status {
            case .readyToPlay:
                duration = item.duration.seconds
                break
            case .failed:
                break
            case .unknown:
                break
            }
        case PlayerItemObserverKey.loadedTimeRanges.rawValue:
            if let loadedTimeRanges = player.currentItem?.loadedTimeRanges, let first = loadedTimeRanges.first {
                let timeRange = first.timeRangeValue
                let startSeconds = CMTimeGetSeconds(timeRange.start)
                let durationSecound = CMTimeGetSeconds(timeRange.duration)
                let result = startSeconds + durationSecound
                didLoadedDuration = Float(result / item.duration.seconds)
            }
            break
        default:
            break
        }
    }
}

extension Player {
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerInterval), userInfo: nil, repeats: true)
        timer?.fireDate = Date()
    }
    
    func timerInterval() {
        if let playerItem = playerItem {
            if playerItem.duration.timescale != 0 {
                let currentTime = CMTimeGetSeconds(self.player!.currentTime())
                currentDuration = Float(currentTime)
            }
        }
    }
}

extension Player {
    func addApplicationNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationWillResignActive),
                                               name: Notification.Name.UIApplicationWillResignActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationDidBecomeActive),
                                               name: Notification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    func removeApplicationNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationWillResignActive,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationDidBecomeActive,
                                                  object: nil)
    }
    
    func applicationWillResignActive() {
        pause()
    }
    
    func applicationDidBecomeActive() {
        play()
    }
}

extension Player {
    func convert(duration: Float) -> String {
        let min = Int(duration / 60)
        let sec = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
}

extension UIView {
    func fadeIn() {
        UIView.animate(withDuration: 1) {
            self.alpha = 1
        }
    }
    
    func fadeOut() {
        UIView.animate(withDuration: 1) {
            self.alpha = 0
        }
    }
}
