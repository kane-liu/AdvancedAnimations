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
    
    // UI
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
            height: self.view.frame.height - commentViewHeight
        )
        commentDummyView.image = UIImage(named: "comments")
        commentDummyView.contentMode = .scaleAspectFill
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
        return self.view.frame
    }
    
    private func collapsedFrame() -> CGRect {
        return CGRect(
            x: 0,
            y: self.view.frame.height - commentViewHeight,
            width: self.view.frame.width,
            height: commentViewHeight)
    }
    
    private func fractionComplete(withTranslation translation: CGPoint) -> CGFloat {
        return fabs(translation.y) / (self.view.frame.height - commentViewHeight) + progressWhenInterrupted
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
        self.animateOrReverseRunningTransition(state: self.nextState(), duration: 1)
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.startInteractiveTransition(state: self.nextState(), duration: 1)
        case .changed:
            let translation = recognizer.translation(in: commentView)
            self.updateInteractiveTransition(fractionComplete: self.fractionComplete(withTranslation: translation))
        case .ended:
            self.continueInteractiveTransition(cancel: false)
        default:
            break
        }
    }
    
    // MARK: Animation
    // Perform all animations with animators if not already running
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
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
                case .start, .end:
                    self.state = self.nextState()
                    self.runningAnimators.removeAll()
                default:
                    break
                }
            })
            frameAnimator.pauseAnimation()
            progressWhenInterrupted = frameAnimator.fractionComplete
            runningAnimators.append(frameAnimator)
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
        self.animateTransitionIfNeeded(state: state, duration: 1)
    }
    
    // Scrubs transition on pan .changed
    func updateInteractiveTransition(fractionComplete: CGFloat) {
        if !runningAnimators.isEmpty {
            runningAnimators.forEach({ $0.fractionComplete = fractionComplete })
        }
    }
    
    // Continues or reverse transition on pan .ended
    func continueInteractiveTransition(cancel: Bool) {
        if !runningAnimators.isEmpty {
            let timing = UICubicTimingParameters(animationCurve: .easeOut)
            runningAnimators.forEach({ $0.continueAnimation(withTimingParameters: timing, durationFactor: 0) })
        }
    }
}

