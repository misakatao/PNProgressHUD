//
//  ProgressHUD.swift
//
//  Created by Misaka on 2023/6/1.
//

import Foundation
import UIKit

extension ProgressHUD {
    public static let didReceiveTouchEventNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.DidReceiveTouchEventNotification")
    public static let didTouchDownInsideNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.DidTouchDownInsideNotification")
    public static let willDisappearNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.WillDisappearNotification")
    public static let didDisappearNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.DidDisappearNotification")
    public static let willAppearNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.WillAppearNotification")
    public static let didAppearNotification: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.DidAppearNotification")
    public static let statusUserInfoKey: NSNotification.Name = NSNotification.Name(rawValue: "ProgressHUD.StatusUserInfoKey")
    
    public static let parallaxDepthPoints: CGFloat = 10.0
    public static let undefinedProgress: CGFloat = -1
    public static let defaultAnimationDuration: CGFloat = 0.15
    public static let verticalSpacing: CGFloat = 12.0
    public static let horizontalSpacing: CGFloat = 12.0
    public static let labelSpacing: CGFloat = 8.0
}

public class ProgressHUD : UIView {
    
    public enum Style {
        case light
        case dark
        case custom
    }

    public enum MaskType {
        case none
        case clear
        case black
        case gradient
        case custom
    }

    public enum AnimationType {
        case flat
        case native
    }
    
    public static let currentBundle: Bundle = {
        let bundle = Bundle(for: ProgressHUD.self)
        guard let url = bundle.url(forResource: "ProgressHUD", withExtension: "bundle") else { return Bundle.main }
        guard let imageBundle = Bundle(url: url) else { return Bundle.main }
        return imageBundle
    }()
    
    public static func getBundleImage(_ named: String?) -> String {
        return ProgressHUD.currentBundle.path(forResource: named, ofType: "png") ?? ""
    }
    
    public var defaultStyle: ProgressHUD.Style = .dark
    public var defaultMaskType: ProgressHUD.MaskType = .none
    public var defaultAnimationType: ProgressHUD.AnimationType = .flat
    
    public var containerView: UIView?
    
    public var minimumSize: CGSize = .zero
    public var ringThickness: CGFloat = 2.0
    public var ringRadius: CGFloat = 18.0
    public var ringNoTextRadius: CGFloat = 24.0
    public var cornerRadius: CGFloat = 14.0
    public var font: UIFont = UIFont.preferredFont(forTextStyle: .subheadline)
    
    public var customColor: UIColor = UIColor.white
    public var foregroundColor: UIColor = UIColor.black
    public var foregroundImageColor: UIColor?
    public var backgroundLayerColor: UIColor = UIColor(white: 0, alpha: 0.4)
    
    public var imageViewSize: CGSize = CGSizeMake(28, 28)
    public var shouldTintImages: Bool = true
    
    public var infoImage: UIImage? = UIImage(contentsOfFile: ProgressHUD.getBundleImage("info"))
    public var successImage: UIImage? = UIImage(contentsOfFile: ProgressHUD.getBundleImage("success"))
    public var errorImage: UIImage? = UIImage(contentsOfFile: ProgressHUD.getBundleImage("error"))
    
    public var graceTimeInterval: TimeInterval = 0
    public var minimumDismissTimeInterval: TimeInterval = 5.0
    public var maximumDismissTimeInterval: TimeInterval = CGFLOAT_MAX
    
    public var offsetFromCenter: UIOffset = .zero
    public var fadeInAnimationDuration: TimeInterval = ProgressHUD.defaultAnimationDuration
    public var fadeOutAnimationDuration: TimeInterval = ProgressHUD.defaultAnimationDuration
    public var maxSupportedWindowLevel: UIWindow.Level = .normal
    public var hapticsEnabled: Bool = false
    public var motionEffectEnabled: Bool = true
    public var shouldSingleLabel: Bool = false
    
    private var graceTimer: Timer?
    private var fadeOutTimer: Timer?
    
    private lazy var controlView: UIControl = {
        let control = UIControl(frame: .zero)
        control.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        control.backgroundColor = UIColor.clear
        control.isUserInteractionEnabled = true
        control.addTarget(self, action: #selector(controlViewDidReceiveTouchEvent(_:event:)), for: .touchDown)
        if let windowBounds = UIApplication.shared.delegate?.window??.bounds {
            control.frame = windowBounds
        } else {
            control.frame = UIScreen.main.bounds
        }
        return control
    }()
    
    private var backgroundView: UIView?
    private func getBackgroundView() -> UIView {
        if backgroundView == nil {
            let view = UIView(frame: .zero)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundView = view
        }
        
        if let view = backgroundView, view.superview == nil {
            insertSubview(view, belowSubview: getHudView())
        }
        // Update styling
        if defaultMaskType == .gradient {
            if backgroundRadialGradientLayer == nil {
                backgroundRadialGradientLayer = YJRadialGradientLayer()
            }
            if let gradientLayer = backgroundRadialGradientLayer, gradientLayer.superlayer == nil {
                backgroundView?.layer.insertSublayer(gradientLayer, at: 0)
            }
            backgroundView?.backgroundColor = UIColor.clear
        } else {
            if let gradientLayer = backgroundRadialGradientLayer, gradientLayer.superlayer != nil {
                gradientLayer.removeFromSuperlayer()
            }
            if defaultMaskType == .black {
                backgroundView?.backgroundColor = UIColor(white: 0, alpha: 0.4)
            } else if defaultMaskType == .custom {
                backgroundView?.backgroundColor = backgroundLayerColor
            } else {
                backgroundView?.backgroundColor = UIColor.clear
            }
        }
        
        backgroundView?.frame = bounds
        if let gradientLayer = backgroundRadialGradientLayer {
            gradientLayer.frame = bounds
            var gradientCenter = center
            gradientCenter.y = (bounds.height - visibleKeyboardHeight) / 2
            gradientLayer.gradientCenter = gradientCenter
            gradientLayer.setNeedsDisplay()
        }
        
        return backgroundView!
    }
    
    private var backgroundRadialGradientLayer: YJRadialGradientLayer?
    
    private var hudView: UIVisualEffectView?
    private func getHudView() -> UIVisualEffectView {
        if hudView == nil {
            let view = UIVisualEffectView()
            view.layer.masksToBounds = true
            view.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleLeftMargin]
            hudView = view
        }
        
        if let view = hudView, view.superview == nil {
            addSubview(view)
        }
        // Update styling
        hudView?.layer.cornerRadius = cornerRadius
        return hudView!
    }
    
    private var hudViewCustomBlurEffect: UIBlurEffect?
    
    private var statusLabel: UILabel?
    private func getStatusLabel() -> UILabel {
        if statusLabel == nil {
            let label = UILabel(frame: .zero)
            label.backgroundColor = UIColor.clear
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.baselineAdjustment = .alignCenters
            label.numberOfLines = 0
            statusLabel = label
        }
        
        if let view = statusLabel, view.superview == nil {
            getHudView().contentView.addSubview(view)
        }
        // Update styling
        statusLabel?.textColor = foregroundColorForStyle
        statusLabel?.font = font
        return statusLabel!
    }
    
    private var imageView: UIImageView?
    private func getImageView() -> UIImageView {
        if let view = imageView, !CGSizeEqualToSize(view.bounds.size, imageViewSize) {
            view.removeFromSuperview()
            imageView = nil
        }
        if imageView == nil {
            let view = UIImageView(frame: CGRectMake(0, 0, imageViewSize.width, imageViewSize.height))
            imageView = view
        }
        if let view = imageView, view.superview == nil {
            getHudView().contentView.addSubview(view)
        }
        return imageView!
    }
    
    // MARK: - Ring progress animation
    private var indefiniteAnimatedView: UIView?
    private func getIndefiniteAnimatedView() -> UIView {
        
        if defaultAnimationType == .flat {
            if let existingView = indefiniteAnimatedView, !(existingView is YJIndefiniteAnimatedView) {
                existingView.removeFromSuperview()
                indefiniteAnimatedView = nil
            }
            
            if indefiniteAnimatedView == nil {
                let view = YJIndefiniteAnimatedView()
                view.strokeColor = foregroundImageColorForStyle
                view.strokeThickness = ringThickness
                view.radius = getStatusLabel().text != nil ? ringRadius : ringNoTextRadius
                indefiniteAnimatedView = view
            }
        } else {
            if let existingView = indefiniteAnimatedView, !(existingView is UIActivityIndicatorView) {
                existingView.removeFromSuperview()
                indefiniteAnimatedView = nil
            }
            
            if indefiniteAnimatedView == nil {
                let view = UIActivityIndicatorView(style: .whiteLarge)
                view.color = foregroundImageColorForStyle
                indefiniteAnimatedView = view
            }
        }
        indefiniteAnimatedView?.sizeToFit()
        return indefiniteAnimatedView!
    }
    
    private var ringView: YJProgressAnimatedView?
    private func getRingView() -> YJProgressAnimatedView {
        if ringView == nil {
            ringView = YJProgressAnimatedView()
        }
        // Update styling
        ringView?.strokeColor = foregroundColorForStyle
        ringView?.strokeThickness = ringThickness
        ringView?.radius = getStatusLabel().text != nil ? ringRadius : ringNoTextRadius
        return ringView!
    }
    
    private var backgroundRingView: YJProgressAnimatedView?
    private func getBackgroundRingView() -> YJProgressAnimatedView {
        if backgroundRingView == nil {
            backgroundRingView = YJProgressAnimatedView()
            backgroundRingView?.strokeEnd = 1.0
        }
        // Update styling
        backgroundRingView?.strokeColor = foregroundColorForStyle.withAlphaComponent(0.1)
        backgroundRingView?.strokeThickness = ringThickness
        backgroundRingView?.radius = getStatusLabel().text != nil ? ringRadius : ringNoTextRadius
        return backgroundRingView!
    }
    
    private var progress: CGFloat = 0
    private var activityCount: Int = 0
    
    private var visibleKeyboardHeight: CGFloat {
        
        var keyboardWindow: UIWindow?
        for window in UIApplication.shared.windows where type(of: window) != UIWindow.self {
            keyboardWindow = window
            break
        }
        if let keyboardWindow = keyboardWindow {
            for possibleKeyboard in keyboardWindow.subviews {
                let viewName = String(describing: type(of: possibleKeyboard))
                if viewName.hasPrefix("UI") {
                    if viewName.hasSuffix("PeripheralHostView") || viewName.hasSuffix("Keyboard") {
                        return possibleKeyboard.bounds.height
                    } else if viewName.hasSuffix("InputSetContainerView") {
                        for possibleKeyboardSubview in possibleKeyboard.subviews {
                            let subviewName = String(describing: type(of: possibleKeyboardSubview))
                            if subviewName.hasPrefix("UI") && subviewName.hasSuffix("InputSetHostView") {
                                let convertedRect = possibleKeyboard.convert(possibleKeyboardSubview.frame, to: self)
                                let intersectedRect = convertedRect.intersection(self.bounds)
                                if !intersectedRect.isNull {
                                    return intersectedRect.height
                                }
                            }
                        }
                    }
                }
            }
        }
        return 0
    }
    
    private lazy var frontWindow: UIWindow? = {
        for window in UIApplication.shared.windows.reversed() {
            let windowOnMainScreen = window.screen == UIScreen.main
            let windowIsVisible = !window.isHidden && window.alpha > 0
            let windowLevelSupported = (window.windowLevel >= .normal && window.windowLevel <= maxSupportedWindowLevel)
            let windowKeyWindow = window.isKeyWindow
            
            if windowOnMainScreen && windowIsVisible && windowLevelSupported && windowKeyWindow {
                return window
            }
        }
        return nil
    }()
    
    private lazy var hapticGenerator: UINotificationFeedbackGenerator? = {
        return hapticsEnabled ? UINotificationFeedbackGenerator() : nil
    }()
    
    private var isInitializing: Bool = true
    
    private var foregroundColorForStyle: UIColor {
        switch defaultStyle {
        case .light:
            return UIColor.black
        case .dark:
            return UIColor.white
        case .custom:
            return foregroundColor
        }
    }
    
    private var foregroundImageColorForStyle: UIColor {
        if let foregroundImageColor = foregroundImageColor {
            return foregroundImageColor
        } else {
            return foregroundColorForStyle
        }
    }
    
    private var backgroundColorForStyle: UIColor {
        switch defaultStyle {
        case .light:
            return UIColor.white
        case .dark:
            return UIColor.black
        case .custom:
            return customColor
        }
    }
    
    private var notificationUserInfo: [NSNotification.Name : Any]? {
        if let text = getStatusLabel().text {
            return [ ProgressHUD.statusUserInfoKey : text ]
        }
        return nil
    }
    
    private static let shared = ProgressHUD(frame: UIScreen.main.bounds)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        getBackgroundView().alpha = 0
        getImageView().alpha = 0
        getStatusLabel().alpha = 0
        getIndefiniteAnimatedView().alpha = 0
        getRingView().alpha = 0
        getBackgroundRingView().alpha = 0
        
        // backgroundColor = UIColor.white
        isInitializing = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateHUDFrame() {
        
        let imageUsed = getImageView().image != nil && !getImageView().isHidden
        let progressUsed = getImageView().isHidden
        
        var labelRect = CGRect.zero
        var labelWidth: CGFloat = 0.0
        var labelHeight: CGFloat = 0.0
        
        if let text = getStatusLabel().text {
            let constraintSize = CGSize(width: 200.0, height: 300.0)
            let textAttributes: [NSAttributedString.Key : Any] = [.font : getStatusLabel().font as Any]
            labelRect = NSString(string: text).boundingRect(with: constraintSize,
                                                            options: [.usesFontLeading, .truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                                            attributes: textAttributes,
                                                            context: nil)
            labelWidth = ceil(labelRect.width)
            labelHeight = ceil(labelRect.height)
        }
        
        var hudWidth: CGFloat
        var hudHeight: CGFloat
        
        var contentWidth: CGFloat = 0.0
        var contentHeight: CGFloat = 0.0
        
        if imageUsed || progressUsed {
            contentWidth = imageUsed ? getImageView().frame.width : (shouldSingleLabel ? 0.0 : getIndefiniteAnimatedView().frame.width)
            contentHeight = imageUsed ? getImageView().frame.height : (shouldSingleLabel ? 0.0 : getIndefiniteAnimatedView().frame.height)
        }
        
        hudWidth = ProgressHUD.horizontalSpacing + max(labelWidth, contentWidth) + ProgressHUD.horizontalSpacing
        
        // |-spacing-content-(labelSpacing-label-)spacing-|
        hudHeight = ProgressHUD.verticalSpacing + labelHeight + contentHeight + ProgressHUD.verticalSpacing
        if let _ = getStatusLabel().text, (imageUsed || progressUsed) {
            // Add spacing if both content and label are used
            hudHeight += ProgressHUD.labelSpacing
        }
        
        // Update values on subviews
        getHudView().bounds = CGRect(x: 0.0, y: 0.0, width: max(minimumSize.width, hudWidth), height: max(minimumSize.height, hudHeight))
        
        // Animate value update
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Spinner and image view
        var centerY: CGFloat
        if let _ = getStatusLabel().text {
            let yOffset = max(ProgressHUD.verticalSpacing, (minimumSize.height - contentHeight - ProgressHUD.labelSpacing - labelHeight) / 2.0)
            centerY = yOffset + contentHeight / 2.0
        } else {
            centerY = getHudView().bounds.midY
        }
        getIndefiniteAnimatedView().center = CGPoint(x: getHudView().bounds.midX, y: centerY)
        if progress != ProgressHUD.undefinedProgress {
            getRingView().center = CGPoint(x: getHudView().bounds.midX, y: centerY)
            getBackgroundRingView().center = getRingView().center
        }
        getImageView().center = CGPoint(x: getHudView().bounds.midX, y: centerY)
        
        // Label
        if imageUsed || progressUsed {
            centerY = (imageUsed ? getImageView().frame.maxY : getIndefiniteAnimatedView().frame.maxY) + ProgressHUD.labelSpacing + labelHeight / 2.0
        } else {
            centerY = getHudView().bounds.midY
        }
        getStatusLabel().frame = labelRect
        getStatusLabel().center = CGPoint(x: getHudView().bounds.midX, y: centerY)
        
        CATransaction.commit()
    }
    
    private func updateMotionEffect(_ orientation: UIInterfaceOrientation) {
        let xMotionEffectType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongHorizontalAxis : .tiltAlongVerticalAxis
        let yMotionEffectType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongVerticalAxis : .tiltAlongHorizontalAxis
        updateMotionEffectType(x: xMotionEffectType, y: yMotionEffectType)
    }
    
    private func updateMotionEffectType(x xMotionEffectType: UIInterpolatingMotionEffect.EffectType, y yMotionEffectType: UIInterpolatingMotionEffect.EffectType) {
        let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        effectX.minimumRelativeValue = -ProgressHUD.parallaxDepthPoints
        effectX.maximumRelativeValue = ProgressHUD.parallaxDepthPoints

        let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        effectY.minimumRelativeValue = -ProgressHUD.parallaxDepthPoints
        effectY.maximumRelativeValue = ProgressHUD.parallaxDepthPoints

        let effectGroup = UIMotionEffectGroup()
        effectGroup.motionEffects = [effectX, effectY]

        // Clear old motion effect, then add new motion effects
        getHudView().motionEffects = []
        getHudView().addMotionEffect(effectGroup)
    }
    
    private func updateViewHierarchy() {
        if let superview = controlView.superview {
            superview.bringSubviewToFront(controlView)
        } else {
            if let containerView = containerView {
                containerView.addSubview(controlView)
            } else {
                frontWindow?.addSubview(controlView)
            }
        }
        if superview == nil {
            controlView.addSubview(self)
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func positionHUD(_ notification: Notification?) {
        var keyboardHeight: CGFloat = 0.0
        var animationDuration: Double = 0.0
        
        frame = UIApplication.shared.delegate?.window??.bounds ?? CGRect.zero
        let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        if let notification = notification as? NSNotification, let keyboardInfo = notification.userInfo {
            let keyboardFrame = (keyboardInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
            animationDuration = keyboardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.0
            
            if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardDidShowNotification {
                keyboardHeight = keyboardFrame.width
                
                if orientation.isPortrait {
                    keyboardHeight = keyboardFrame.height
                }
            }
        } else {
            keyboardHeight = visibleKeyboardHeight
        }
        
        let orientationFrame = bounds
        let statusBarFrame = UIApplication.shared.statusBarFrame
        
        if motionEffectEnabled {
            updateMotionEffect(orientation)
        }
        
        var activeHeight = orientationFrame.height
        if keyboardHeight > 0 {
            activeHeight += statusBarFrame.height * 2
        }
        activeHeight -= keyboardHeight
        
        let posX = orientationFrame.midX
        let posY = floor(activeHeight * 0.45)
        
        let rotateAngle: CGFloat = 0.0
        let newCenter = CGPoint(x: posX, y: posY)
        
        if let _ = notification as? NSNotification {
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.moveToPoint(newCenter, rotateAngle: rotateAngle)
                self.getHudView().setNeedsDisplay()
            }, completion: nil)
        } else {
            moveToPoint(newCenter, rotateAngle: rotateAngle)
        }
    }
    
    private func moveToPoint(_ newCenter: CGPoint, rotateAngle angle: CGFloat) {
        getHudView().transform = CGAffineTransform(rotationAngle: angle)
        if let containerView = containerView {
            getHudView().center = CGPoint(x: containerView.center.x + offsetFromCenter.horizontal, y: containerView.center.y + offsetFromCenter.vertical)
        } else {
            getHudView().center = CGPoint(x: newCenter.x + offsetFromCenter.horizontal, y: newCenter.y + offsetFromCenter.vertical)
        }
    }
    
    @objc private func controlViewDidReceiveTouchEvent(_ sender: Any, event: UIEvent) {
        
        NotificationCenter.default.post(name: ProgressHUD.didReceiveTouchEventNotification, object: self, userInfo: notificationUserInfo)
        
        if let touch = event.allTouches?.first {
            let touchLocation = touch.location(in: self)
            
            if CGRectContainsPoint(getHudView().frame, touchLocation) {
                NotificationCenter.default.post(name: ProgressHUD.didTouchDownInsideNotification, object: self, userInfo: notificationUserInfo)
            }
        }
    }
    
    private func displayDurationFor(_ string: String?) -> TimeInterval {
        let minimum = max(CGFloat(string?.count ?? 0) * 0.06 + 0.5, ProgressHUD.shared.minimumDismissTimeInterval)
        return min(minimum, ProgressHUD.shared.maximumDismissTimeInterval)
    }
    
    private func cancelRingLayerAnimation() {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        getHudView().layer.removeAllAnimations()
        getRingView().strokeEnd = 0
        
        CATransaction.commit()
        
        getRingView().removeFromSuperview()
        getBackgroundRingView().removeFromSuperview()
    }
    
    private func cancelIndefiniteAnimatedViewAnimation() {
        
        if getIndefiniteAnimatedView().responds(to: #selector(UIActivityIndicatorView.stopAnimating)) {
            (getIndefiniteAnimatedView() as? UIActivityIndicatorView)?.stopAnimating()
        }
        
        getIndefiniteAnimatedView().removeFromSuperview()
    }
}

// MARK: - Show Methods
extension ProgressHUD {
    
    public class func show(_ status: String? = nil, _ progress: CGFloat = ProgressHUD.undefinedProgress) {
        let hud = ProgressHUD.shared
        hud.shouldSingleLabel = false
        hud.show(status, progress: progress)
    }
    
    public class func showMessage(_ message: String?) {
        let hud = ProgressHUD.shared
        hud.shouldSingleLabel = true
        hud.showImage(nil, status: message, duration: hud.displayDurationFor(message))
    }
    
    public class func showInfo(_ status: String?) {
        let hud = ProgressHUD.shared
        hud.shouldSingleLabel = false
        hud.showImage(hud.infoImage, status: status, duration: hud.displayDurationFor(status))
        
        DispatchQueue.main.async {
            hud.hapticGenerator?.notificationOccurred(.warning)
        }
    }
    
    public class func showSuccess(_ status: String?) {
        let hud = ProgressHUD.shared
        hud.shouldSingleLabel = false
        hud.showImage(hud.successImage, status: status, duration: hud.displayDurationFor(status))
        
        DispatchQueue.main.async {
            hud.hapticGenerator?.notificationOccurred(.success)
        }
    }
    
    public class func showError(_ status: String?) {
        let hud = ProgressHUD.shared
        hud.shouldSingleLabel = false
        hud.showImage(hud.errorImage, status: status, duration: hud.displayDurationFor(status))
        
        DispatchQueue.main.async {
            hud.hapticGenerator?.notificationOccurred(.error)
        }
    }
    
    public class func dismiss(_ delay: TimeInterval = 0, _ completion: (() -> Void)? = nil) {
        ProgressHUD.shared.dismiss(delay, completion)
    }
    
    private func show(_ status: String?, progress: CGFloat) {
        
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            
            if self.fadeOutTimer != nil {
                self.activityCount = 0
            }
            // Stop timer
            self.fadeOutTimer?.invalidate()
            self.fadeOutTimer = nil
            self.graceTimer?.invalidate()
            self.graceTimer = nil
            
            // Update / Check view hierarchy to ensure the HUD is visible
            self.updateViewHierarchy()
            
            // Reset imageView and fadeout timer if an image is currently displayed
            self.getImageView().isHidden = true
            self.getImageView().image = nil
            
            // Update text and set progress to the given value
            if status?.count ?? 0 > 0 {
                self.getStatusLabel().isHidden = false
            } else {
                self.getStatusLabel().isHidden = true
            }
            self.getStatusLabel().text = status
            self.progress = progress
            
            // Choose the "right" indicator depending on the progress
            if progress >= 0 {
                // Cancel the indefiniteAnimatedView, then show the ringLayer
                self.cancelIndefiniteAnimatedViewAnimation()
                
                // Add ring to HUD
                if self.getRingView().superview == nil {
                    self.getHudView().contentView.addSubview(self.getRingView())
                }
                if self.getBackgroundRingView().superview == nil {
                    self.getHudView().contentView.addSubview(self.getBackgroundRingView())
                }
                
                // Set progress animated
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.getRingView().strokeEnd = progress
                CATransaction.commit()
                
                // Update the activity count
                if progress == 0 {
                    self.activityCount += 1
                }
            } else {
                // Cancel the ringLayer animation, then show the indefiniteAnimatedView
                self.cancelRingLayerAnimation()
                
                // Add indefiniteAnimatedView to HUD
                self.getHudView().contentView.addSubview(self.getIndefiniteAnimatedView())
                
                if let view = self.getIndefiniteAnimatedView() as? UIActivityIndicatorView {
                    view.startAnimating()
                }
                
                // Update the activity count
                self.activityCount += 1
            }
            
            // Fade in delayed if a grace time is set
            if self.graceTimeInterval > 0 && self.getBackgroundView().alpha == 0 {
                self.graceTimer = Timer(timeInterval: self.graceTimeInterval, target: self, selector: #selector(self.fadeIn(_:)), userInfo: nil, repeats: false)
                RunLoop.main.add(self.graceTimer!, forMode: .common)
            } else {
                self.fadeIn()
            }
            
            // Tell the Haptics Generator to prepare for feedback, which may come soon
            self.hapticGenerator?.prepare()
        }
    }
    
    private func showImage(_ image: UIImage?, status: String?, duration: TimeInterval) {
        
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            
            // Stop timer
            self.fadeOutTimer?.invalidate()
            self.fadeOutTimer = nil
            self.graceTimer?.invalidate()
            self.graceTimer = nil
            
            // Update / Check view hierarchy to ensure the HUD is visible
            self.updateViewHierarchy()
            
            // Reset progress and cancel any running animation
            self.progress = ProgressHUD.undefinedProgress
            self.cancelRingLayerAnimation()
            self.cancelIndefiniteAnimatedViewAnimation()
            
            // Update imageView
            if self.shouldTintImages {
                if image?.renderingMode != .alwaysTemplate {
                    self.getImageView().image = image?.withRenderingMode(.alwaysTemplate)
                } else {
                    self.getImageView().image = image
                }
                self.getImageView().tintColor = self.foregroundImageColorForStyle
            } else {
                self.getImageView().image = image
            }
            self.getImageView().isHidden = false
            
            // Update text
            if status?.count ?? 0 > 0 {
                self.getStatusLabel().isHidden = false
            } else {
                self.getStatusLabel().isHidden = true
            }
            self.getStatusLabel().text = status
            
            // Fade in delayed if a grace time is set
            // An image will be dismissed automatically. Thus pass the duration as userInfo.
            if self.graceTimeInterval > 0 && self.getBackgroundView().alpha == 0 {
                let graceTimer = Timer(timeInterval: self.graceTimeInterval, target: self, selector: #selector(self.fadeIn(_:)), userInfo: nil, repeats: false)
                RunLoop.main.add(graceTimer, forMode: .common)
                self.graceTimer = graceTimer
            } else {
                self.fadeIn(duration)
            }
        }
    }
    
    @objc private func fadeIn(_ data: Any? = nil) {
        // Update the HUDs frame to the new content and position HUD
        updateHUDFrame()
        positionHUD(nil)
        
        if defaultMaskType != .none {
            controlView.isUserInteractionEnabled = true
        } else {
            controlView.isUserInteractionEnabled = false
        }
        
        // Show if not already visible
        if getBackgroundView().alpha != 1.0 {
            // Post notification to inform user
            NotificationCenter.default.post(name: ProgressHUD.willAppearNotification, object: self, userInfo: notificationUserInfo)
            
            // Zoom HUD a little to to make a nice appear / pop up animation
            getHudView().transform = getHudView().transform.scaledBy(x: 1.3, y: 1.3)
            
            let animationsBlock: () -> Void = {
                // Zoom HUD a little to make a nice appear / pop up animation
                self.getHudView().transform = .identity
                // Fade in all effects (colors, blur, etc.)
                self.fadeInEffects()
            }
            
            let completionBlock: () -> Void = {
                // Check if we really achieved to show the HUD (<=> alpha)
                // and the change of these values has not been cancelled in between e.g. due to a dismissal
                if self.getBackgroundView().alpha == 1.0 {
                    // Register observer <=> we now have to handle orientation changes etc.
                    self.registerNotifications()
                    
                    // Post notification to inform user
                    NotificationCenter.default.post(name: ProgressHUD.didAppearNotification, object: self, userInfo: self.notificationUserInfo)
                    
                    // Dismiss automatically if a duration was passed as userInfo. We start a timer
                    // which then will call dismiss after the predefined duration
                    if let duration = data as? TimeInterval {
                        let fadeOutTimer = Timer(timeInterval: duration, target: self, selector: #selector(self.dismissEmpty), userInfo: nil, repeats: false)
                        RunLoop.main.add(fadeOutTimer, forMode: .common)
                        self.fadeOutTimer = fadeOutTimer
                    }
                }
            }
            
            // Animate appearance
            if fadeInAnimationDuration > 0 {
                UIView.animate(withDuration: fadeInAnimationDuration, delay: 0, options: [.allowUserInteraction, .curveEaseIn, .beginFromCurrentState], animations: {
                    animationsBlock()
                }) { finished in
                    completionBlock()
                }
            } else {
                animationsBlock()
                completionBlock()
            }
            
            // Inform iOS to redraw the view hierarchy
            setNeedsDisplay()
        } else {
            // Dismiss automatically if a duration was passed as userInfo. We start a timer
            // which then will call dismiss after the predefined duration
            if let duration = data as? TimeInterval {
                let fadeOutTimer = Timer(timeInterval: duration, target: self, selector: #selector(dismissEmpty), userInfo: nil, repeats: false)
                RunLoop.main.add(fadeOutTimer, forMode: .common)
                self.fadeOutTimer = fadeOutTimer
            }
        }
    }
    
    private func fadeInEffects() {
        
        if defaultStyle != .custom {
            let blurEffectStyle: UIBlurEffect.Style = defaultStyle == .dark ? .dark : .light
            let blurEffect = UIBlurEffect(style: blurEffectStyle)
            getHudView().effect = blurEffect
            getHudView().backgroundColor = backgroundColorForStyle.withAlphaComponent(0.6)
        } else {
            getHudView().effect = hudViewCustomBlurEffect
            getHudView().backgroundColor = backgroundColorForStyle
        }
        
        getBackgroundView().alpha = 1.0
        getImageView().alpha = 1.0
        getStatusLabel().alpha = 1.0
        getIndefiniteAnimatedView().alpha = 1.0
        getRingView().alpha = 1.0
        getBackgroundRingView().alpha = 1.0
    }
    
    private func fadeOutEffects() {
        
        if defaultStyle != .custom {
            getHudView().effect = nil
        }
        
        getHudView().backgroundColor = .clear
        
        // Fade out views
        getBackgroundView().alpha = 0.0
        getImageView().alpha = 0.0
        getStatusLabel().alpha = 0.0
        getIndefiniteAnimatedView().alpha = 0.0
        getRingView().alpha = 0.0
        getBackgroundRingView().alpha = 0.0
    }

    @objc private func dismissEmpty() {
        dismiss(0, nil)
    }
    
    public func dismiss(_ delay: TimeInterval, _ completion: (() -> Void)?) {
        
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            
            // Post notification to inform user
            NotificationCenter.default.post(name: ProgressHUD.willDisappearNotification, object: nil, userInfo: self.notificationUserInfo)
            
            // Reset activity count
            self.activityCount = 0
            
            let animationsBlock: () -> Void = {
                // Shrink HUD a little to make a nice disappear animation
                self.getHudView().transform = self.getHudView().transform.scaledBy(x: 1/1.3, y: 1/1.3)
                
                // Fade out all effects (colors, blur, etc.)
                self.fadeOutEffects()
            }
            
            let completionBlock: () -> Void = {
                // Check if we really achieved to dismiss the HUD (<=> alpha values are applied)
                // and the change of these values has not been cancelled in between e.g. due to a new show
                if self.getBackgroundView().alpha == 0.0 {
                    // Clean up view hierarchy (overlays)
                    self.controlView.removeFromSuperview()
                    self.getBackgroundView().removeFromSuperview()
                    self.getHudView().removeFromSuperview()
                    self.removeFromSuperview()
                    
                    // Reset progress and cancel any running animation
                    self.progress = ProgressHUD.undefinedProgress
                    self.cancelRingLayerAnimation()
                    self.cancelIndefiniteAnimatedViewAnimation()
                    
                    // Remove observer <=> we do not have to handle orientation changes etc.
                    NotificationCenter.default.removeObserver(self)
                    
                    // Post notification to inform user
                    NotificationCenter.default.post(name: ProgressHUD.didDisappearNotification, object: self, userInfo: self.notificationUserInfo)
                    
                    // Tell the rootViewController to update the StatusBar appearance
                    if let rootController = UIApplication.shared.keyWindow?.rootViewController {
                        rootController.setNeedsStatusBarAppearanceUpdate()
                    }
                    
                    // Run an (optional) completionHandler
                    completion?()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                
                self.graceTimer?.invalidate()
                self.graceTimer = nil
                
                if self.fadeOutAnimationDuration > 0 {
                    // Animate appearance
                    UIView.animate(withDuration: self.fadeOutAnimationDuration, delay: 0, options: [.allowUserInteraction, .curveEaseOut, .beginFromCurrentState], animations: {
                        animationsBlock()
                    }) { finished in
                        completionBlock()
                    }
                } else {
                    animationsBlock()
                    completionBlock()
                }
            }
            
            // Inform iOS to redraw the view hierarchy
            self.setNeedsDisplay()
        }
    }
}

public class YJIndefiniteAnimatedView : UIView {
    
    public var strokeThickness: CGFloat = 0 {
        didSet {
            getIndefiniteAnimatedLayer().lineWidth = strokeThickness
        }
    }
    
    public var radius: CGFloat = 0 {
        didSet {
            getIndefiniteAnimatedLayer().removeFromSuperlayer()
            indefiniteAnimatedLayer = nil
            
            if superview != nil {
                setNeedsLayout()
            }
        }
    }
    
    public var strokeColor: UIColor? {
        didSet {
            getIndefiniteAnimatedLayer().strokeColor = strokeColor?.cgColor
        }
    }
    
    private var indefiniteAnimatedLayer: CAShapeLayer?
    private func getIndefiniteAnimatedLayer() -> CAShapeLayer {
        let arcCenter = CGPoint(x: radius + strokeThickness / 2 + 5, y: radius + strokeThickness / 2 + 5)
        let smoothedPath = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: CGFloat(Double.pi * 3 / 2), endAngle: CGFloat(Double.pi / 2 + Double.pi * 5), clockwise: true)
        
        if indefiniteAnimatedLayer == nil {
            let shapeLayer = CAShapeLayer()
            shapeLayer.contentsScale = UIScreen.main.scale
            shapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: arcCenter.x * 2, height: arcCenter.y * 2)
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = strokeColor?.cgColor
            shapeLayer.lineWidth = strokeThickness
            shapeLayer.lineCap = .round
            shapeLayer.lineJoin = .bevel
            shapeLayer.path = smoothedPath.cgPath
            
            let maskLayer = CALayer()
            
            maskLayer.contents = UIImage(contentsOfFile: ProgressHUD.getBundleImage("angle-mask"))?.cgImage
            maskLayer.frame = shapeLayer.bounds
            shapeLayer.mask = maskLayer
            
            let animationDuration: TimeInterval = 1
            let linearCurve = CAMediaTimingFunction(name: .linear)
            
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = 0
            animation.toValue = Double.pi * 2
            animation.duration = animationDuration
            animation.timingFunction = linearCurve
            animation.isRemovedOnCompletion = false
            animation.repeatCount = Float.infinity
            animation.fillMode = .forwards
            animation.autoreverses = false
            
            maskLayer.add(animation, forKey: "rotate")
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = animationDuration
            animationGroup.repeatCount = .infinity
            animationGroup.isRemovedOnCompletion = false
            animationGroup.timingFunction = linearCurve
            
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = 0.015
            strokeStartAnimation.toValue = 0.515
            
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = 0.485
            strokeEndAnimation.toValue = 0.985
            
            animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
            shapeLayer.add(animationGroup, forKey: "progress")
            
            indefiniteAnimatedLayer = shapeLayer
        }
        return indefiniteAnimatedLayer!
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            setNeedsLayout()
        } else {
            getIndefiniteAnimatedLayer().removeFromSuperlayer()
            indefiniteAnimatedLayer = nil
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
         
        layoutAnimatedLayer()
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: (radius + strokeThickness / 2 + 5.0) * 2, height: (radius + strokeThickness / 2 + 5.0) * 2)
    }
    
    private func layoutAnimatedLayer() {
        
        let animatedLayer = getIndefiniteAnimatedLayer()
        if animatedLayer.superlayer == nil {
            layer.addSublayer(animatedLayer)
        }
        
        let widthDiff = bounds.width - animatedLayer.bounds.width
        let heightDiff = bounds.height - animatedLayer.bounds.height
        animatedLayer.position = CGPoint(x: bounds.width - animatedLayer.bounds.width / 2 - widthDiff / 2, y: bounds.height - animatedLayer.bounds.height / 2 - heightDiff / 2)
    }
}

public class YJProgressAnimatedView : UIView {
    
    public var strokeColor: UIColor? {
        didSet {
            getRingAnimatedLayer().strokeColor = strokeColor?.cgColor
        }
    }
    
    public var strokeThickness: CGFloat = 0 {
        didSet {
            getRingAnimatedLayer().lineWidth = strokeThickness
        }
    }
    
    public var strokeEnd: CGFloat = 0 {
        didSet {
            getRingAnimatedLayer().strokeEnd = strokeEnd
        }
    }
    
    public var radius: CGFloat = 0 {
        didSet {
            getRingAnimatedLayer().removeFromSuperlayer()
            ringAnimatedLayer = nil
            
            if superview != nil {
                layoutAnimatedLayer()
            }
        }
    }
    
    private var ringAnimatedLayer: CAShapeLayer?
    private func getRingAnimatedLayer() -> CAShapeLayer {
        if ringAnimatedLayer == nil {
            let layer = CAShapeLayer()
            let arcCenter = CGPoint(x: (radius + strokeThickness / 2 + 5.0), y: (radius + strokeThickness / 2 + 5.0))
            layer.contentsScale = UIScreen.main.scale
            layer.frame = CGRect(x: 0, y: 0, width: arcCenter.x * 2, height: arcCenter.y * 2)
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = strokeColor?.cgColor
            layer.lineWidth = strokeThickness
            layer.lineCap = .round
            layer.lineJoin = .bevel
            layer.path = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: Double.pi / 2, endAngle: Double.pi + Double.pi / 2, clockwise: true).cgPath
            ringAnimatedLayer = layer
        }
        return ringAnimatedLayer!
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            setNeedsLayout()
        } else {
            getRingAnimatedLayer().removeFromSuperlayer()
            ringAnimatedLayer = nil
        }
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: (radius + strokeThickness / 2 + 5.0) * 2, height: (radius + strokeThickness / 2 + 5.0) * 2)
    }
    
    private func layoutAnimatedLayer() {
        
        let animatedLayer = getRingAnimatedLayer()
        if animatedLayer.superlayer == nil {
            layer.addSublayer(animatedLayer)
        }
        
        let widthDiff = bounds.width - animatedLayer.bounds.width
        let heightDiff = bounds.height - animatedLayer.bounds.height
        animatedLayer.position = CGPoint(x: bounds.width - animatedLayer.bounds.width / 2 - widthDiff / 2, y: bounds.height - animatedLayer.bounds.height / 2 - heightDiff / 2)
    }
}

public class YJRadialGradientLayer : CALayer {
    
    public var gradientCenter: CGPoint = .zero
    
    public override func draw(in ctx: CGContext) {
        let locationsCount: size_t = 2
        var locations: [CGFloat] = [0.0, 1.0]
        var colors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: &colors, locations: &locations, count: locationsCount)!
        // CGColorSpaceRelease(colorSpace)
        
        let radius = min(self.bounds.size.width, self.bounds.size.height)
        ctx.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: radius, options: CGGradientDrawingOptions.drawsAfterEndLocation)
    }
}
