//
//  FoldedTableViewCell.swift
//  FoldedCell
//
//  Created by Thiago Lourin on 11/02/20.
//  Copyright © 2020 Lourin. All rights reserved.
//

import UIKit

open class FoldedTableViewCell: UITableViewCell {

    open var isFolded: Bool = true
    var animation: UIView?
    var animationItemViews: [RotatedUIView]?
    
    @IBInspectable open var itemCount: NSInteger = 1
    @IBInspectable open var backgroundViewColor: UIColor = UIColor.cyan
    
    @IBOutlet open var containerView: UIView!
    @IBOutlet open var containerViewTop: NSLayoutConstraint!
    @IBOutlet open var foregroundView: RotatedUIView!
    @IBOutlet open var foregroundViewTop: NSLayoutConstraint!
    
    open var durationsForExpandedState: [TimeInterval] = []
    open var durationsForCollapsedState: [TimeInterval] = []
            
    open override func awakeFromNib() {
        super.awakeFromNib()
    }

    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    open func unfold(_ value: Bool, animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            value ? openAnimation(completion) : closeAnimation(completion)
        } else {
            foregroundView.alpha = value ? 0 : 1
            containerView.alpha = value ? 1 : 0
        }
    }
    
    func openAnimation(_ completion: (() -> Void)?) {
        isFolded = false
        removeImageItemsFromAnimationView()
        addImageItemsToAnimationView()
        
        animation?.alpha = 1
        containerView.alpha = 0
        
        let durations = durationSequence(.open)
        
        var delay: TimeInterval = 0
        var timing = CAMediaTimingFunctionName.easeIn.rawValue
        var from: CGFloat = 0.0
        var to: CGFloat = -CGFloat.pi / 2
        var hidden = true
        configureAnimationItems(AnimationType.open)
        
        guard let animationItemViews = self.animationItemViews else {
            return
        }
        
        for index in 0 ..< animationItemViews.count {
            let animatedView = animationItemViews[index]
            
            animatedView.foldingAnimation(timing, from: from, to: to, duration: durations[index], delay: delay, hidden: hidden)
            
            from = from == 0.0 ? CGFloat.pi / 2 : 0.0
            to = to == 0.0 ? -CGFloat.pi / 2 : 0.0
            timing = timing == CAMediaTimingFunctionName.easeIn.rawValue ? CAMediaTimingFunctionName.easeOut.rawValue : CAMediaTimingFunctionName.easeIn.rawValue
            hidden = !hidden
            delay += durations[index]
        }
        
        let firstItemView = animation?.subviews.filter { $0.tag == 0 }.first
        
        firstItemView?.layer.masksToBounds = true
        DispatchQueue.main.asyncAfter(deadline: .now() + durations[0], execute: {
            firstItemView?.layer.cornerRadius = 0
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.animation?.alpha = 0
            self.containerView.alpha = 1
            completion?()
        }
    }
    
    func closeAnimation(_ completion: (() -> Void)?) {
        isFolded = true
        removeImageItemsFromAnimationView()
        addImageItemsToAnimationView()
        
        guard let animationItemViews = self.animationItemViews else {
            fatalError()
        }
        
        animation?.alpha = 1
        containerView.alpha = 0
        
        let durations: [TimeInterval] = durationSequence(AnimationType.closed).reversed()
        
        var delay: TimeInterval = 0
        var timing = CAMediaTimingFunctionName.easeIn.rawValue
        var from: CGFloat = 0.0
        var to: CGFloat = CGFloat.pi / 2
        var hidden = true
        configureAnimationItems(AnimationType.closed)
        
        if durations.count < animationItemViews.count {
            fatalError("wrong override func animationDuration(itemIndex:NSInteger, type:AnimationType)-> NSTimeInterval")
        }
        for index in 0 ..< animationItemViews.count {
            let animatedView = animationItemViews.reversed()[index]
            
            animatedView.foldingAnimation(timing, from: from, to: to, duration: durations[index], delay: delay, hidden: hidden)
            
            to = to == 0.0 ? CGFloat.pi / 2 : 0.0
            from = from == 0.0 ? -CGFloat.pi / 2 : 0.0
            timing = timing == CAMediaTimingFunctionName.easeIn.rawValue ? CAMediaTimingFunctionName.easeOut.rawValue : CAMediaTimingFunctionName.easeIn.rawValue
            hidden = !hidden
            delay += durations[index]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            self.animation?.alpha = 0
            completion?()
        })
        
        let firstItemView = animation?.subviews.filter { $0.tag == 0 }.first
        firstItemView?.layer.cornerRadius = 0
        firstItemView?.layer.masksToBounds = true
        if let durationFirst = durations.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay - durationFirst * 2, execute: {
                firstItemView?.layer.cornerRadius = self.foregroundView.layer.cornerRadius
                firstItemView?.setNeedsDisplay()
                firstItemView?.setNeedsLayout()
            })
        }
    }
    
    func configureAnimationItems(_ animationType: AnimationType) {
        if animationType == .open {
            animation?.subviews
                .lazy
                .compactMap { $0 as? RotatedUIView }
                .forEach { $0.alpha = 0 }
        } else {
            animation?.subviews
                .lazy
                .compactMap { $0 as? RotatedUIView }
                .forEach {
                    $0.alpha = animationType == .open ? 0 : 1
                    if animationType != .open { $0.backView?.alpha = 0 }
            }
        }
    }
    
    open func isAnimating() -> Bool {
        return animation?.alpha == 1 ? true : false
    }
    
    open dynamic func animationDuration(_ itemIndex: NSInteger, type: AnimationType) -> TimeInterval {
        return type == AnimationType.closed ? durationsForCollapsedState[itemIndex] : durationsForExpandedState[itemIndex]
    }
    
    private func configureDefaultState() {
        guard let foregroundViewTop = self.foregroundViewTop, let containerViewTop = self.containerViewTop else {
            fatalError("Out of outlets for foregroundTop and cointainerTop")
        }
        
        containerViewTop.constant = foregroundViewTop.constant
        containerView.alpha = 0
        
        if let height = (foregroundView.constraints.filter { $0.firstAttribute == .height && $0.secondItem == nil }).first?.constant {
            foregroundView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
            foregroundViewTop.constant += height / 2
        }
        foregroundView.layer.transform = foregroundView.transform3D()
        
        createAnimationView()
        contentView.bringSubviewToFront(foregroundView)
    }
    
    private func createAnimationItemView() -> [RotatedUIView] {
        var items = [RotatedUIView]()
        var rotatedUIViews = [RotatedUIView]()
        items.append(foregroundView)
        
        animation?.subviews.lazy.compactMap( { $0 as? RotatedUIView } )
            .sorted(by: { $0.tag < $1.tag })
            .forEach{
                item in rotatedUIViews.append(item)
                if let backView = item.backView {
                    rotatedUIViews.append(backView)
                }
        }
        
        items.append(contentsOf: rotatedUIViews)
        
        return items
    }
    
    func createAnimationView() {
        animation = UIView(frame: containerView.frame)
        animation?.layer.cornerRadius = foregroundView.layer.cornerRadius
        animation?.backgroundColor = .clear
        animation?.translatesAutoresizingMaskIntoConstraints = false
        animation?.alpha = 0
        
        guard let animationView = self.animation else { return }
        
        self.contentView.addSubview(animationView)
                
        var newConstraints = [NSLayoutConstraint]()
        for constraint in self.contentView.constraints {
            if let item = constraint.firstItem as? UIView, item == containerView {
                let newConstraint = NSLayoutConstraint(item: animationView, attribute: constraint.firstAttribute,
                                                       relatedBy: constraint.relation, toItem: constraint.secondItem, attribute: constraint.secondAttribute,
                                                       multiplier: constraint.multiplier, constant: constraint.constant)
                
                newConstraints.append(newConstraint)
            } else if let firstItem = constraint.firstItem as? UIView, let secondItem: UIView = constraint.secondItem as? UIView, secondItem == containerView {
                let newConstraint = NSLayoutConstraint(item: firstItem, attribute: constraint.firstAttribute,
                                                       relatedBy: constraint.relation, toItem: animationView, attribute: constraint.secondAttribute,
                                                       multiplier: constraint.multiplier, constant: constraint.constant)
                
                newConstraints.append(newConstraint)
            }
        }
        self.contentView.addConstraints(newConstraints)
        
        for constraint in containerView.constraints {
            if constraint.firstAttribute == .height, let item: UIView = constraint.firstItem as? UIView, item == containerView {
                let newConstraint = NSLayoutConstraint(item: animationView, attribute: constraint.firstAttribute,
                                                       relatedBy: constraint.relation, toItem: nil, attribute: constraint.secondAttribute,
                                                       multiplier: constraint.multiplier, constant: constraint.constant)
                
                animationView.addConstraint(newConstraint)
            }
        }
    }
    
    func addImageItemsToAnimationView() {
        containerView.alpha = 1
        let containerViewSize = containerView.bounds.size
        let foregroundViewSize = foregroundView.bounds.size
        
        var image = containerView.takeSnapshot(CGRect(x: 0, y: 0, width: containerViewSize.width, height: foregroundViewSize.height))
        var imageView = UIImageView(image: image)
        imageView.tag = 0
        imageView.layer.cornerRadius = foregroundView.layer.cornerRadius
        animation?.addSubview(imageView)
                
        image = containerView.takeSnapshot(CGRect(x: 0, y: foregroundViewSize.height, width: containerViewSize.width, height: foregroundViewSize.height))
        
        imageView = UIImageView(image: image)
        let rotatedView = RotatedUIView(frame: imageView.frame)
        rotatedView.tag = 1
        rotatedView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        rotatedView.layer.transform = rotatedView.transform3D()
        
        rotatedView.addSubview(imageView)
        animation?.addSubview(rotatedView)
        rotatedView.frame = CGRect(x: imageView.frame.origin.x, y: foregroundViewSize.height, width: containerViewSize.width, height: foregroundViewSize.height)
                
        let itemHeight = (containerViewSize.height - 2 * foregroundViewSize.height) / CGFloat(itemCount - 2)
        
        if itemCount == 2 {
            assert(containerViewSize.height - 2 * foregroundViewSize.height == 0, "contanerView.height too high")
        } else {
            assert(containerViewSize.height - 2 * foregroundViewSize.height >= itemHeight, "contanerView.height too high")
        }
        
        var yPosition = 2 * foregroundViewSize.height
        var tag = 2
        for _ in 2 ..< itemCount {
            image = containerView.takeSnapshot(CGRect(x: 0, y: yPosition, width: containerViewSize.width, height: itemHeight))
            
            imageView = UIImageView(image: image)
            let rotatedView = RotatedUIView(frame: imageView.frame)
            
            rotatedView.addSubview(imageView)
            rotatedView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
            rotatedView.layer.transform = rotatedView.transform3D()
            animation?.addSubview(rotatedView)
            rotatedView.frame = CGRect(x: 0, y: yPosition, width: rotatedView.bounds.size.width, height: itemHeight)
            rotatedView.tag = tag
            
            yPosition += itemHeight
            tag += 1
        }
        
        containerView.alpha = 0
        
        if let animationView = self.animation {
            var previuosView: RotatedUIView?
            for case let container as RotatedUIView in animationView.subviews.sorted(by: { $0.tag < $1.tag })
                where container.tag > 0 && container.tag < animationView.subviews.count {
                    previuosView?.addBackView(height: container.bounds.size.height, color: backgroundViewColor)
                    previuosView = container
            }
        }
        animationItemViews = createAnimationItemView()
    }
    
    fileprivate func removeImageItemsFromAnimationView() {
        
        guard let animationView = self.animation else {
            return
        }
        
        animationView.subviews.forEach({ $0.removeFromSuperview() })
    }
    
    func durationSequence(_ type: AnimationType) -> [TimeInterval] {
        var durations = [TimeInterval]()
        for i in 0 ..< itemCount - 1 {
            let duration = animationDuration(i, type: type)
            durations.append(TimeInterval(duration / 2.0))
            durations.append(TimeInterval(duration / 2.0))
        }
        return durations
    }
}
