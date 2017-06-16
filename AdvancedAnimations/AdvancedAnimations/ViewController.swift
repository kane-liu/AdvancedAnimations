//
//  ViewController.swift
//  AdvancedAnimations
//
//  Created by kane-liu on 2017/06/14.
//  Copyright © 2017年 Ryu Ka. All rights reserved.
//

import UIKit

enum State {
    case collapsed
    case expanded
}

class ViewController: UIViewController {
    
    // Constant
    let commentViewHeight: CGFloat = 64.0
    let animatorDuration: TimeInterval = 1
    
    // UI
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var commentHeaderView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    var commentView = UIView()
    var commentTitleLabel = UILabel()
    var commentDummyView = UIImageView()
    
    // Tracks all running aninmators
    var progressWhenInterrupted: CGFloat = 0
    var runningAnimators = [UIViewPropertyAnimator]()
    var state: State = .collapsed
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initSubViews()
        self.addGestures()
    }

    private func initSubViews() {
        self.blurEffectView.effect = nil
        
        // Collapsed comment view
        commentView.frame = self.collapsedFrame()
        commentView.backgroundColor = .white
        self.view.addSubview(commentView)
        
        // Title label
        commentTitleLabel.text = "Comments"
        commentTitleLabel.sizeToFit()
        commentTitleLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        commentTitleLabel.center = CGPoint(x: self.view.frame.width / 2, y: commentViewHeight / 2)
        commentView.addSubview(commentTitleLabel)
        
        // Dummy view
        commentDummyView.frame = CGRect(
            x: 0.0,
            y: commentViewHeight,
            width: self.view.frame.width,
            height: self.view.frame.height - commentViewHeight - self.headerView.frame.height
        )
        commentDummyView.image = UIImage(named: "comments")
        commentDummyView.contentMode = .scaleAspectFit
        commentView.addSubview(commentDummyView)
    }
    
    private func addGestures() {
        // Tap gesture
        commentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:))))
        
        // Pan gesutre
        commentView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:))))
    }
    
    // MARK: Util
    private func expandedFrame() -> CGRect {
        return CGRect(
            x: 0,
            y: self.headerView.frame.height,
            width: self.view.frame.width,
            height: self.view.frame.height - self.headerView.frame.height
        )
    }
    
    private func collapsedFrame() -> CGRect {
        return CGRect(
            x: 0,
            y: self.view.frame.height - commentViewHeight,
            width: self.view.frame.width,
            height: commentViewHeight)
    }
    
    private func fractionComplete(withTranslation translation: CGPoint) -> CGFloat {
        return fabs(translation.y) / (self.view.frame.height - commentViewHeight - self.headerView.frame.height) + progressWhenInterrupted
    }
    
    private func nextState() -> State {
        switch self.state {
        case .collapsed:
            return .expanded
        case .expanded:
            return .collapsed
        }
    }
    
    // MARK: Gesture
    @objc private func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        self.animateOrReverseRunningTransition(state: self.nextState(), duration: animatorDuration)
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: commentView)
        
        switch recognizer.state {
        case .began:
            self.startInteractiveTransition(state: self.nextState(), duration: animatorDuration)
        case .changed:
            self.updateInteractiveTransition(fractionComplete: self.fractionComplete(withTranslation: translation))
        case .ended:
            self.continueInteractiveTransition(fractionComplete: self.fractionComplete(withTranslation: translation))
        default:
            break
        }
    }
    
    @IBAction func didTapCloseButton(_ sender: UIButton) {
        if self.state == .expanded {
            self.animateOrReverseRunningTransition(state: self.nextState(), duration: animatorDuration)
        }
    }
    // MARK: Animation
    // Frame Animation
    private func addFrameAnimator(state: State, duration: TimeInterval) {
        // Frame Animation
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.commentView.frame = self.expandedFrame()
            case .collapsed:
                self.commentView.frame = self.collapsedFrame()
            }
        }
        frameAnimator.addCompletion({ (position) in
            switch position {
            case .start:
                // Fix blur animator bug don't know why
                switch self.state {
                case .expanded:
                    self.blurEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.blurEffectView.effect = nil
                }
            case .end:
                self.state = self.nextState()
            default:
                break
            }
            self.runningAnimators.removeAll()
        })
        progressWhenInterrupted = frameAnimator.fractionComplete
        runningAnimators.append(frameAnimator)
    }
    
    // Blur Animation
    private func addBlurAnimator(state: State, duration: TimeInterval) {
        var timing: UITimingCurveProvider
        switch state {
        case .expanded:
            timing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.75, y: 0.1), controlPoint2: CGPoint(x: 0.9, y: 0.25))
        case .collapsed:
            timing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.1, y: 0.75), controlPoint2: CGPoint(x: 0.25, y: 0.9))
        }
        let blurAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
        if #available(iOS 11, *) {
            blurAnimator.scrubsLinearly = false
        }
        blurAnimator.addAnimations {
            switch state {
            case .expanded:
                self.blurEffectView.effect = UIBlurEffect(style: .dark)
            case .collapsed:
                self.blurEffectView.effect = nil
            }
        }
        runningAnimators.append(blurAnimator)
    }
    
    // Label Scale Animation
    private func addLabelScaleAnimator(state: State, duration: TimeInterval) {
        let scaleAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.commentTitleLabel.transform = CGAffineTransform.identity.scaledBy(x: 1.8, y: 1.8)
            case .collapsed:
                self.commentTitleLabel.transform = CGAffineTransform.identity
            }
        }
        runningAnimators.append(scaleAnimator)
    }
    
    // CornerRadius Animation
    private func addCornerRadiusAnimator(state: State, duration: TimeInterval) {
        commentView.clipsToBounds = true
        // Corner mask
        if #available(iOS 11, *) {
            commentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.commentView.layer.cornerRadius = 12
            case .collapsed:
                self.commentView.layer.cornerRadius = 0
            }
        }
        runningAnimators.append(cornerRadiusAnimator)
    }
    
    // KeyFrame Animation
    private func addKeyFrameAnimator(state: State, duration: TimeInterval) {
        let keyFrameAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
                switch state {
                case .expanded:
                    UIView.addKeyframe(withRelativeStartTime: duration / 2, relativeDuration: duration / 2, animations: {
                        self.commentHeaderView.alpha = 1
                        self.backButton.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
                        self.closeButton.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
                    })
                case .collapsed:
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: duration / 2, animations: {
                        self.commentHeaderView.alpha = 0
                        self.backButton.transform = CGAffineTransform.identity
                        self.closeButton.transform = CGAffineTransform.identity
                    })
                }
            }, completion: nil)
        }
        runningAnimators.append(keyFrameAnimator)
    }
    
    // Perform all animations with animators if not already running
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            self.addFrameAnimator(state: state, duration: duration)
            self.addBlurAnimator(state: state, duration: duration)
            self.addLabelScaleAnimator(state: state, duration: duration)
            self.addCornerRadiusAnimator(state: state, duration: duration)
            self.addKeyFrameAnimator(state: state, duration: duration)
        }
    }
    
    // Starts transition if necessary or reverse it on tap
    func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
            runningAnimators.forEach({ $0.startAnimation() })
        } else {
            runningAnimators.forEach({ $0.isReversed = !$0.isReversed })
        }
    }
    
    // Starts transition if necessary and pauses on pan .began
    func startInteractiveTransition(state: State, duration: TimeInterval) {
        self.animateTransitionIfNeeded(state: state, duration: duration)
        // For iOS10 need to pause here
        runningAnimators.forEach({ $0.pauseAnimation() })
    }
    
    // Scrubs transition on pan .changed
    func updateInteractiveTransition(fractionComplete: CGFloat) {
        runningAnimators.forEach({ $0.fractionComplete = fractionComplete })
    }
    
    // Continues or reverse transition on pan .ended
    func continueInteractiveTransition(fractionComplete: CGFloat) {
        let cancel: Bool = fractionComplete < 0.25
        
        if cancel {
            runningAnimators.forEach({
                $0.isReversed = !$0.isReversed
                $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            })
            return
        }
        
        let timing = UICubicTimingParameters(animationCurve: .easeOut)
        runningAnimators.forEach({ $0.continueAnimation(withTimingParameters: timing, durationFactor: 0) })
    }
}

