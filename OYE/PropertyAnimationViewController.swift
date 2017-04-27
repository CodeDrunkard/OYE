//
//  PropertyAnimationViewController.swift
//  OYE
//
//  Created by JT Ma on 26/04/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class PropertyAnimationViewController: UIViewController {
    
    var circleCenter: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let circle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
        circle.center = self.view.center
        circle.layer.cornerRadius = 50.0
        circle.backgroundColor = UIColor.green
        
        circle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragCircle)))
        
        self.view.addSubview(circle)
    }
    
    func dragCircle(gesture: UIPanGestureRecognizer) {
        let target = gesture.view!
        
        switch gesture.state {
        case .began:
            circleCenter = target.center
        case .changed:
            let translation = gesture.translation(in: self.view)
            target.center = CGPoint(x: circleCenter!.x + translation.x, y: circleCenter!.y + translation.y)
        default: break
        }
    }
}
