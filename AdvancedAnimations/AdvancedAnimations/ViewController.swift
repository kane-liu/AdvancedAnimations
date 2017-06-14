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
    
    let commentViewHeight: CGFloat = 64.0
    
    var commentView = UIView()
    var commentTitleLabel = UILabel()
    var commentDummyView = UIImageView()
    
    // Tracks all running aninmators
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
        // Collapsed xomment view
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
    
    private func addGestures() {
        // Tap gesture
        commentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:))))
        
        // Pan gesutre
        commentView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:))))
    }
    
    private func nextState() -> State {
        switch self.state {
        case .collapsed:
            return .expanded
        case .expanded:
            return .collapsed
        }
    }
    
    @objc private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        animator = UIViewPropertyAnimator(duration: 1, curve: .easeOut, animations: {
            switch self.nextState() {
            case .collapsed:
                self.commentView.frame = self.collapsedFrame()
            case .expanded:
                self.commentView.frame = self.expandedFrame()
            }
        })
        animator.addCompletion({ (position) in
            if position == .end {
                self.state = self.nextState()
            }
        })
        animator.startAnimation()
    }
    
    var animator: UIViewPropertyAnimator!
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            animator = UIViewPropertyAnimator(duration: 1, curve: .easeOut, animations: {
                switch self.nextState() {
                case .collapsed:
                    self.commentView.frame = self.collapsedFrame()
                case .expanded:
                    self.commentView.frame = self.expandedFrame()
                }
            })
            animator.addCompletion({ (position) in
                if position == .end {
                    self.state = self.nextState()
                }
            })
            animator.pauseAnimation()
        case .changed:
            let translation = sender.translation(in: commentView)
            animator.fractionComplete = fabs(translation.y) / (self.view.frame.height - commentViewHeight)
        case .ended:
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        default:
            break
        }
    }
    
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
            frameAnimator.startAnimation()
            runningAnimators.append(frameAnimator)
        }
    }
    
    // Starts transition if necessary or reverse it on tap
    func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        } else {
            runningAnimators.forEach({ $0.isReversed = !$0.isReversed })
        }
    }
    
    // Starts transition if necessary and pauses on pan .begin
    func startInteractiveTransition(state: State, duration: TimeInterval) {
        
    }
    
    // Scrubs transition on pan .changed
    func updateInteractiveTransition(fractionComplete: CGFloat) {
        
    }
    
    // Continues or reverse transition on pan .ended
    func continueInteractiveTransition(cancel: Bool) {
        
    }
}

