//
//  IOViewController.swift
//  OYE
//
//  Created by JT Ma on 24/04/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

import UIKit

class IOViewController: UIViewController {
    
    let ioView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        ioView.backgroundColor = UIColor.red
        
        view.addSubview(ioView)
        ioView.snp.makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(view.snp.width).multipliedBy(9.0 / 16.0)
            $0.top.equalTo(view).offset(100)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.changeStatusBarOrientation),
                                               name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation,
                                               object: nil)
    }
    
    func changeStatusBarOrientation() {
        if UIApplication.shared.statusBarOrientation.isLandscape {
            ioView.snp.updateConstraints {
                $0.top.equalTo(view).offset(100)
            }
        } else {
            ioView.snp.updateConstraints {
                $0.top.equalTo(view)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.UIApplicationWillChangeStatusBarOrientation,
                                                  object: nil)
    }
}

extension IOViewController {
    override public var shouldAutorotate: Bool {
        return true
    }
    
//    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .portrait
//    }
    
    override public var prefersStatusBarHidden: Bool {
        return false
    }
}
