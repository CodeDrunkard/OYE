//
//  Player.swift
//  OYE
//
//  Created by JT Ma on 30/09/2017.
//  Copyright © 2017 JiangtaoMa<majt@hiscene.com>. All rights reserved.
//

import AVFoundation

public class Player: NSObject {
    
    public var player = AVPlayer()
    
    public var playerItem: AVPlayerItem? {
        didSet {
            playerItem?.addObserver(self, forKeyPath: PlayerItemObserverKey.status.rawValue, options:NSKeyValueObservingOptions.new, context: nil)
            playerItem?.addObserver(self, forKeyPath: PlayerItemObserverKey.loadedTimeRanges.rawValue, options:NSKeyValueObservingOptions.new, context: nil)

            if playerItem != player.currentItem {
                player.replaceCurrentItem(with: playerItem)
            }
        }
    }

    public func play() {
        print("play")
        setupTimer()
        player.play()
    }
    
    public func pause() {
        timer?.invalidate()
        player.pause()
    }
    
    func seek(to seconds: TimeInterval, completionHandler: ((Bool) -> Swift.Void)?) {
        let draggedTime = CMTimeMake(Int64(seconds), 1)
        player.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { finished in
            completionHandler?(finished)
        }
    }
    
    var delegate: PlayerDurationProtocol?
    
    var duration: Float! {
        didSet {
            delegate?.playerTotalDuration(duration: duration)
        }
    }
    
    var didLoadedDuration: Float! {
        didSet {
            delegate?.playerDidLoadedDuration(duration: didLoadedDuration)
        }
    }
    
    var currentDuration: Float! {
        didSet {
            delegate?.playerCurrentDuration(duration: currentDuration)
        }
    }
    
    var timer: Timer?

    enum PlayerItemObserverKey: String {
        case status
        case loadedTimeRanges
        case playbackBufferEmpty
        case playbackLikelyToKeepUp
    }
    
    public override init() {
        super.init()
        addApplicationNotification()
    }
    
    deinit {
        removeApplicationNotification()
    }
}

extension Player {
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem, let key = keyPath else {
            return
        }
        switch key {
        case PlayerItemObserverKey.status.rawValue:
            switch player.status {
            case .readyToPlay:
                setupTimer()
                duration = Float(item.duration.seconds)
                break
            case .failed:
                pause()
                break
            case .unknown:
                pause()
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
    
    @objc func timerInterval() {
        if let playerItem = playerItem {
            if playerItem.duration.timescale != 0 {
                let currentTime = CMTimeGetSeconds(playerItem.currentTime())
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationWillTerminate),
                                               name: Notification.Name.UIApplicationWillTerminate,
                                               object: nil)
    }
    
    func removeApplicationNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationWillResignActive,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationDidBecomeActive,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationWillTerminate,
                                                  object: nil)
    }
    
    @objc func applicationWillResignActive() {
        pause()
    }
    
    @objc func applicationDidBecomeActive() {
        play()
    }
    
    @objc func applicationWillTerminate() {
        pause()
    }
}

protocol PlayerDurationProtocol {
    func playerTotalDuration(duration: Float)
    func playerDidLoadedDuration(duration: Float)
    func playerCurrentDuration(duration: Float)
}
