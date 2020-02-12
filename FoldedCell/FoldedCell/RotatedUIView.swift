//
//  RotatedUIView.swift
//  FoldedCell
//
//  Created by Thiago Lourin on 11/02/20.
//  Copyright © 2020 Lourin. All rights reserved.
//

import UIKit

internal enum Constant {
    static let rotationX = "rotation.x"
    static let transformRotationX = "transform.rotation.x"
    static let x05 = 0.5
    static let x1 = 1.0
}

open class RotatedUIView: UIView {

    
    var hiddenAfterAnimation = false
    var backView: RotatedUIView?
    
    func addBackView(height: CGFloat, color: UIColor) {
        let view = RotatedUIView(frame: CGRect.zero)
        view.backgroundColor = color
        view.layer.anchorPoint = CGPoint(x: Constant.x05, y: Constant.x1)
        view.layer.transform = view.transform3D()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(view)
        backView = view
        
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: height))
        
        self.addConstraints([
            NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: self.bounds.size.height - height + height / 2),
            NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            ])
    }
}

extension RotatedUIView: CAAnimationDelegate {
    
    public func animationDidStart(_ anim: CAAnimation) {
        self.layer.shouldRasterize = true
        self.alpha = 1
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (hiddenAfterAnimation) {
            self.alpha = 0
        }
        
        self.layer.shouldRasterize = false
        self.layer.removeAllAnimations()
        self.rotatedX(CGFloat.zero)
    }
    
    func rotatedX(_ angle: CGFloat) {
        var transform = CATransform3DIdentity
        let rotateTransform = CATransform3DMakeRotation(angle, 1, 0, 0)
        transform = CATransform3DConcat(transform, rotateTransform)
        transform = CATransform3DConcat(transform, transform3D())
        
        self.layer.transform = transform
    }
    
    func transform3D() -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = 2.5 / -2000
        
        return transform
    }
    
    func foldingAnimation(_ timing: String, from: CGFloat, to: CGFloat, duration: TimeInterval, delay: TimeInterval, hidden: Bool) {
        
        let rotate = CABasicAnimation(keyPath: Constant.transformRotationX)
        rotate.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName(rawValue: timing))
        rotate.duration = duration
        rotate.beginTime = CACurrentMediaTime() + delay
        rotate.fillMode = CAMediaTimingFillMode.forwards
        rotate.isRemovedOnCompletion = false
        rotate.fromValue = from
        rotate.toValue = to
        rotate.delegate = self
                
        hiddenAfterAnimation = hidden
        self.layer.add(rotate, forKey: Constant.rotationX)
    }
    
}
