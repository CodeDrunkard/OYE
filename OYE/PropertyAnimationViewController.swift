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
    var circleAnimator: UIViewPropertyAnimator!
    let animationDuration = 0.3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let circle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
        circle.center = view.center
        circle.layer.cornerRadius = 50.0
        circle.backgroundColor = UIColor.green
        circle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragCircle)))
        view.addSubview(circle)
        
        circleAnimator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeInOut)
    }
    
    func dragCircle(gesture: UIPanGestureRecognizer) {
        let target = gesture.view!
        
        switch gesture.state {
        case .began, .ended:
            circleCenter = target.center
            
            circleAnimator.stopAnimation(true)
            
            if gesture.state == .began {
                circleAnimator.addAnimations {
                    target.backgroundColor = .red
                    target.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
                }
            } else {
                circleAnimator.addAnimations {
                    target.backgroundColor = .green
                    target.transform = CGAffineTransform.identity
                }
            }
            
            circleAnimator.startAnimation()
            
        case .changed:
            let translation = gesture.translation(in: view)
            target.center = CGPoint(x: circleCenter!.x + translation.x, y: circleCenter!.y + translation.y)
            
        default: break
        }
    }
}
