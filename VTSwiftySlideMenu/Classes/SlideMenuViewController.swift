//
//  SlideMenuViewController.swift
//  Pods-VTSwiftySlideMenu_Example
//
//  Created by Vu Dinh Vinh on 9/14/18.
//

import UIKit

protocol SlideMenuViewControllerDelegate: class
{
    func shouldHandleSlideMenuGesture(viewController: SlideMenuViewController, startPonint: CGPoint, endPoint: CGPoint, isGoingToShowMenuWhenThisGestureSucceeds: Bool) -> Bool
    func willShowMenu(viewController: SlideMenuViewController) -> Void
    func didShowMenu(viewController: SlideMenuViewController) -> Void
    func willHideMenu(viewController: SlideMenuViewController) -> Void
    func didHideMenu(viewController: SlideMenuViewController) -> Void
}

extension UINavigationController
{
    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        // reduce the existing viewController stack
        self.popToRootViewController(animated: false)
        // set a new rootViewController
        if (animated)
        {
            Utilities.animateTransitionController(viewController, duration: 0.6, withType: CATransitionType.reveal.rawValue)
        }
        self.setViewControllers([viewController], animated: false)
    }
}

extension UIViewController
{
    func slideMenuViewController() -> SlideMenuViewController {
        var currentViewController = self.parent
        while (currentViewController != nil)
        {
            if (currentViewController?.isKind(of: SlideMenuViewController.classForCoder()))!
            {
                return currentViewController as! SlideMenuViewController
            }
            currentViewController = currentViewController?.parent!
        }
        return currentViewController as! SlideMenuViewController
    }
    
    func canPerformSegue(withIdentifier id: String) -> Bool {
        guard let segues = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] else { return false }
        return segues.first { $0.value(forKey: "identifier") as? String == id } != nil
    }
    
    func performSegueIfPossible(withIdentifier: String?, sender: AnyObject? = nil) {
        guard let id = withIdentifier, canPerformSegue(withIdentifier: id) else { return }
        self.performSegue(withIdentifier: id, sender: sender)
    }
}

class SlideMenuViewController: UIViewController
{
    let SlideMenuWillShowNotification = "SlideMenuWillShowNotificationInternal"
    let SlideMenuDidShowNotification = "SlideMenuDidShowNotificationInternal"
    let SlideMenuWillHideNotification = "SlideMenuWillHideNotificationInternal"
    let SlideMenuDidHideNotification = "SlideMenuDidHideNotificationInternal"
    
    let kSlideMenuDefaultAnimationDuration = 0.25
    let kSlideMenuDefaultMenuWidth = 280.0
    let kSlideMenuDefaultBounceDuration = 0.2
    
    var isShowShadow: Bool = false
    var isOpaque: Bool = false
    var _hideTapGestureRecognizer: UITapGestureRecognizer?
    var hideTapGestureRecognizer: UITapGestureRecognizer?
    {
        get {
            if _hideTapGestureRecognizer == nil {
                _hideTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.closeTapGestureRecognizerFired(_:)))
                _hideTapGestureRecognizer?.delegate = (self as! UIGestureRecognizerDelegate)
                _hideTapGestureRecognizer?.delaysTouchesBegan = true
                _hideTapGestureRecognizer?.delaysTouchesEnded = true
            }
            return _hideTapGestureRecognizer
        }
        set {
            _hideTapGestureRecognizer = newValue
        }
    }
    var keyboardVisible: Bool = false
    var menuViewVisible: Bool = false {
        didSet {
            if responds(to: #selector(self.setNeedsStatusBarAppearanceUpdate)) {
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    var contentContainerView: UIView?
    var displayMenuSideBySide: Bool = false
    var activeMenuViewController: UIViewController?
    var leftSeparatorView: UIView?
    
    var dragGestureRecognizer: UIGestureRecognizer?
    var dragContentStartX: CGFloat = 0.0
    var dragGestureStartPoint: CGPoint = CGPoint.init(x: 0, y: 0)
    @IBOutlet var leftMenuViewController: UIViewController?
    var _contentViewController: UIViewController?
    @IBOutlet var contentViewController: UIViewController?
    var slideDelegate: SlideMenuViewControllerDelegate?
    var isSupportSwipeGusture: Bool = false
    var tapOnContentViewToHideMenu: Bool = false
    var animationDuration: TimeInterval = 0.0
    var _menuWidth: CGFloat = 0.0
    var menuWidth: CGFloat
    {
        get {
            return _menuWidth
        }
        set {
            _menuWidth = newValue
            if (leftMenuViewController != nil) {
                var menuFrame: CGRect = leftMenuViewController!.view.frame
                menuFrame.size.width = menuAbsoluteWidth()
                leftMenuViewController?.view.frame = menuFrame
            }
        }
    }
    var boucing: Bool = false
    var showLeftMenuLandscape: Bool = false
    var _useShadow: Bool = false
    var useShadow: Bool
    {
        get {
            return _useShadow
        }
        set {
            _useShadow = newValue
            contentContainerView?.clipsToBounds = !useShadow || displayMenuSideBySide
        }
    }
    var shadowView: UIView?
    var _separatorColor: UIColor = UIColor.lightGray
    var separatorColor: UIColor
    {
        get {
            return _separatorColor
        }
        set {
            _separatorColor = newValue
            leftSeparatorView?.backgroundColor = _separatorColor
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        shadowView = UIView(frame: view.bounds)
        shadowView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        //Create GestureRecognizers for NavigationView
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.dragGestureRecognizerDrag(_:)))
        panGR.delegate = self as? UIGestureRecognizerDelegate
        panGR.minimumNumberOfTouches = 1
        panGR.maximumNumberOfTouches = 1
        dragGestureRecognizer = panGR
        view.addGestureRecognizer(dragGestureRecognizer!)
        
        let contentContainer = UIView(frame: view.bounds)
        contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentContainerView = contentContainer
        view.addSubview(contentContainer)
        
        leftSeparatorView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.5, height: view.bounds.size.height))
        leftSeparatorView?.backgroundColor = separatorColor
        leftSeparatorView?.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        leftSeparatorView?.isHidden = true
        contentContainer.addSubview(leftSeparatorView!)
        
        performSegueIfPossible(withIdentifier: "content", sender: self)
        performSegueIfPossible(withIdentifier: "leftMenu", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        updateShadowPath()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    func commonInit()
    {
        animationDuration = kSlideMenuDefaultAnimationDuration
        menuWidth = CGFloat(kSlideMenuDefaultMenuWidth)
        showLeftMenuLandscape = true
        keyboardVisible = false
        boucing = false
        tapOnContentViewToHideMenu = true
        useShadow = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        self.hideTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.closeTapGestureRecognizerFired(_:)))
        self.hideTapGestureRecognizer?.delegate = self as? UIGestureRecognizerDelegate
        self.hideTapGestureRecognizer?.delaysTouchesBegan = true
        self.hideTapGestureRecognizer?.delaysTouchesEnded = true
    }
    
    init()
    {
        super.init(nibName: nil, bundle: nil)
        self.commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func updateShadowBackground()
    {
        if !(shadowView != nil)
        {
            shadowView = UIView(frame: view.bounds)
            shadowView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }
        shadowView?.frame = view.bounds
    }
    
    func updateShadowPath()
    {
        let currentView: UIView? = leftMenuViewController?.view
        currentView?.layer.shadowPath = UIBezierPath(rect: currentView?.bounds ?? CGRect.zero).cgPath
    }
    
    func updateShadowPath(_ trailCollection: UITraitCollection?)
    {
        let currentView: UIView? = leftMenuViewController?.view
        currentView?.layer.shadowPath = UIBezierPath(rect: currentView?.bounds ?? CGRect.zero).cgPath
        if SizeClassHelper.isWideScreen(trailCollection!)
        {
            currentView?.layer.shadowOpacity = 0
        }
        else
        {
            currentView?.layer.shadowOpacity = 1
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        update(super.traitCollection)
        updateShadowPath()
        updateShadowBackground()
    }
    
    func update(_ trailCollection: UITraitCollection?) {
        updateShadowPath(trailCollection)
        var displayMenuSideBySide: Bool
        if SizeClassHelper.trailToString(trailCollection!) != .SplitPortrait
            && SizeClassHelper.trailToString(trailCollection!) != .SplitLandscape
            && SizeClassHelper.trailToString(trailCollection!) != .PhonePortrait
            && SizeClassHelper.trailToString(trailCollection!) != .PhoneLandscape {
            displayMenuSideBySide = true
            showShadowView(false, animated: false)
        } else {
            displayMenuSideBySide = false
        }
        self.displayMenuSideBySide = displayMenuSideBySide
        let offsetLeft: CGFloat = displayMenuSideBySide && self.showLeftMenuLandscape ? self.menuAbsoluteWidth() : 0.0
        self.hideLeftMenu()
        if displayMenuSideBySide {
            self.showLeftMenu()
            self.showShadowView(false, animated: true)
        }
        var frame: CGRect = contentContainerView!.frame
        frame.origin.x = offsetLeft
        frame.size.width = view.bounds.size.width - offsetLeft
        contentContainerView?.frame = frame
        leftSeparatorView?.isHidden = !(displayMenuSideBySide && showLeftMenuLandscape)
        contentContainerView?.clipsToBounds = displayMenuSideBySide || !useShadow
        leftMenuViewController?.view.accessibilityElementsHidden = !displayMenuSideBySide || !showLeftMenuLandscape
    }
    
    // MARK: - Interface rotation
    override var shouldAutorotate: Bool {
        return Bool((contentViewController != nil) ? getTopContentViewController()!.shouldAutorotate : true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (contentViewController != nil) ? getTopContentViewController()!.supportedInterfaceOrientations : .all
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: {
            self.displayMenuSideBySideIfNeeded(toInterfaceOrientation)
        })
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        updateShadowPath()
    }
    
    func displayMenuSideBySideIfNeeded(_ forOriention: UIInterfaceOrientation) {
        
    }
    
    // MARK: - status bar style
    override var childForStatusBarStyle: UIViewController? {
        return menuViewVisible ? activeMenuViewController : contentViewController
    }
    
    func setMenuViewController(_ menuViewController: UIViewController?) {
        setLeftMenu(menuViewController)
    }
    
    func menuViewController() -> UIViewController? {
        return leftMenuViewController
    }
    
    func setLeftMenu(_ menuViewController: UIViewController?) {
        if (leftMenuViewController != nil) {
            leftMenuViewController?.willMove(toParent: nil)
            leftMenuViewController?.view.removeFromSuperview()
            leftMenuViewController?.removeFromParent()
        }
        leftMenuViewController = menuViewController
        if menuViewController != nil {
            let menuView: UIView = (menuViewController?.view)!
            menuView.accessibilityElementsHidden = true
            var menuFrame: CGRect = view.bounds
            menuFrame.size.width = menuAbsoluteWidth()
            menuFrame.origin.x = -menuFrame.size.width - 15
            menuView.frame = menuFrame
            menuView.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
            if let aController = menuViewController {
                addChild(aController)
            }
            view.addSubview(menuView)
            addShadow(to: menuView)
            menuViewController?.didMove(toParent: self)
        }
    }
    
    func setContentViewController(_ contentViewController: UIViewController, animated: Bool) {
        if (self.contentViewController != nil) {
            self.contentViewController?.willMove(toParent: nil)
            self.contentViewController?.view.removeFromSuperview()
            self.contentViewController?.removeFromParent()
        }
        
        self.contentViewController = contentViewController
        
        if (contentViewController is UINavigationController) {
            (contentViewController as? UINavigationController)?.delegate = self as? UINavigationControllerDelegate
        }

        addChild(contentViewController)
        contentViewController.view.frame = (contentContainerView?.bounds)!
        contentViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        var currentFrame: CGRect = view.bounds
        currentFrame.origin.x = currentFrame.size.width
        contentContainerView?.frame = currentFrame
        contentContainerView?.insertSubview(contentViewController.view, at: 0)
        
        if menuViewVisible {
            currentFrame.origin.x = menuAbsoluteWidth()
        } else {
            currentFrame.origin.x = 0
        }

        let animationBlock: (() -> Void)? = {
            self.contentContainerView?.frame = currentFrame
        }
        let completionBlock: ((Bool) -> Void)? = { finished in
            contentViewController.didMove(toParent: self)
        }
        
        if animated {
            if let aBlock = animationBlock {
                UIView.animate(withDuration: kSlideMenuDefaultAnimationDuration, animations: aBlock, completion: completionBlock)
            }
        } else {
            animationBlock?()
            completionBlock?(true)
        }

    }
    
    func dismissContentViewController() {
        contentViewController?.willMove(toParent: nil)
        contentViewController?.view.removeFromSuperview()
        contentViewController?.removeFromParent()
        contentViewController = nil
        
        menuViewVisible = false
    }
    
    func getTopContentViewController() -> UIViewController? {
        if (contentViewController is UINavigationController) {
            return (contentViewController as? UINavigationController)?.topViewController
        }
        return contentViewController
    }

    // MARK: - Screen setup
    func addShadow(to aView: UIView?) {
        aView?.clipsToBounds = !useShadow
        aView?.layer.shadowPath = UIBezierPath(rect: aView?.bounds ?? CGRect.zero).cgPath
        aView?.layer.shadowRadius = 10
        aView?.layer.shadowOpacity = 0.75
        aView?.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        aView?.layer.shadowColor = UIColor.black.cgColor
    }
    
    // MARK: - UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if (navigationController.viewControllers.count < 2) || (navigationController.responds(to: #selector(getter: UINavigationController.supportedInterfaceOrientations)) && (navigationController.supportedInterfaceOrientations == .all)) {
            return
        }
        
        //clang diagnostic push
        //clang diagnostic ignored "-Wundeclared-selector"
        if !responds(to: #selector(getter: self.presentationController)) {
            //clang diagnostic pop
            present(UIViewController(), animated: false) {
                self.dismiss(animated: false)
            }
        }
    }
    
    func showLeftMenu() {
        view.bringSubviewToFront((leftMenuViewController?.view)!)
        
        leftMenuViewController?.view.accessibilityElementsHidden = false
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: leftMenuViewController?.view)
        
        let showMenuCompletionBlock: ((Bool) -> Void)? = { finished in
            self.activeMenuViewController = self.leftMenuViewController
            self.menuViewVisible = true
            if self.tapOnContentViewToHideMenu {
                self.shadowView?.addGestureRecognizer(self.hideTapGestureRecognizer!)
            }
            if (self.slideDelegate != nil) {
                self.slideDelegate?.didShowMenu(viewController: self)
            }
            self.notifyDidShowMenu()
        }

        let showMenuBlock: (() -> Void)? = {
            self.showShadowView(true, animated: true)
            self.view.bringSubviewToFront((self.leftMenuViewController?.view)!)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            contentFrame.origin.x = 0
            self.leftMenuViewController?.view.frame = contentFrame
        }
        
        if (slideDelegate != nil) {
            slideDelegate?.willShowMenu(viewController: self)
        }
        notifyWillShowMenu()
        
        showMenuBlock?();
        showMenuCompletionBlock!(true);
    }
    
    func hideLeftMenu() {
        if (self.leftMenuViewController == nil) {
            return
        }
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: contentViewController?.view)
        leftMenuViewController?.view.accessibilityElementsHidden = true
        
        let hideMenuCompletionBlock: ((Bool) -> Void)? = { finished in
            self.menuViewVisible = false
            if self.tapOnContentViewToHideMenu {
                self.contentContainerView?.removeGestureRecognizer(self.hideTapGestureRecognizer!)
                self.contentViewController?.view.isUserInteractionEnabled = true
            }
            
            if (self.slideDelegate != nil) {
                self.slideDelegate?.didHideMenu(viewController: self)
            }
            self.notifyDidHideMenu()
        }
        let hideMenuBlock: (() -> Void)? = {
            self.showShadowView(false, animated: true)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            contentFrame.origin.x = -contentFrame.size.width - 15
            self.leftMenuViewController?.view.frame = contentFrame
        }
        
        if (slideDelegate != nil) {
            slideDelegate?.willHideMenu(viewController: self)
        }
        notifyWillHideMenu()
        
        hideMenuBlock?()
        hideMenuCompletionBlock!(true)
    }
    
    func hideMenu(_ animated: Bool) {
        if self.displayMenuSideBySide {
            return
        }
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: contentViewController?.view)
        leftMenuViewController?.view.accessibilityElementsHidden = true
        
        let hideMenuCompletionBlock: ((Bool) -> Void)? = { finished in
            self.menuViewVisible = false
            if self.tapOnContentViewToHideMenu {
                self.shadowView?.removeGestureRecognizer(self.hideTapGestureRecognizer!)
            }
            
            if (self.slideDelegate != nil) {
                self.slideDelegate?.didHideMenu(viewController: self)
            }
            self.notifyDidHideMenu()
        }
        let hideBouncingBlock: (() -> Void)? = {
            self.showShadowView(false, animated: true)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            
            contentFrame.origin.x = -contentFrame.size.width - 15
            UIView.animate(withDuration: self.kSlideMenuDefaultBounceDuration, delay: 0.0, options: .curveEaseOut, animations: {
                self.leftMenuViewController?.view.frame = contentFrame
            }) { finished in
                UIView.animate(withDuration: self.kSlideMenuDefaultBounceDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                    self.leftMenuViewController?.view.frame = contentFrame
                }, completion: hideMenuCompletionBlock)
            }
        }
        let hideMenuBlock: (() -> Void)? = {
            self.showShadowView(false, animated: true)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            contentFrame.origin.x = -contentFrame.size.width - 15
            self.leftMenuViewController?.view.frame = contentFrame
        }
        
        if (slideDelegate != nil) {
            slideDelegate?.willHideMenu(viewController: self)
        }
        notifyWillHideMenu()
        
        if animated {
            if self.boucing {
                hideBouncingBlock!()
            } else {
                if let aBlock = hideMenuBlock {
                    UIView.animate(withDuration: TimeInterval(animationDuration), animations: aBlock, completion: hideMenuCompletionBlock)
                }
            }
        } else {
            hideMenuBlock?()
            hideMenuCompletionBlock!(true)
        }
    }
    
    func showMenu(_ viewController: UIViewController, animated: Bool) {
        if self.displayMenuSideBySide {
            return
        }
        view.bringSubviewToFront((leftMenuViewController?.view)!)
        
        viewController.view.accessibilityElementsHidden = false
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: viewController.view)
        
        let showMenuCompletionBlock: ((Bool) -> Void)? = { finished in
            self.activeMenuViewController = viewController
            self.menuViewVisible = true
            if self.tapOnContentViewToHideMenu {
                self.shadowView?.addGestureRecognizer(self.hideTapGestureRecognizer!)
            }
            if (self.slideDelegate != nil) {
                self.slideDelegate?.didShowMenu(viewController: self)
            }
            self.notifyDidShowMenu()
        }
        let showBouncingBlock: (() -> Void)? = {
            self.showShadowView(true, animated: true)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            contentFrame.origin.x = 0
            
            UIView.animate(withDuration: self.kSlideMenuDefaultBounceDuration, delay: 0.0, options: .curveEaseOut, animations: {
                self.leftMenuViewController?.view.frame = contentFrame
            }) { finished in
                UIView.animate(withDuration: self.kSlideMenuDefaultBounceDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                    self.leftMenuViewController?.view.frame = contentFrame
                }, completion: showMenuCompletionBlock)
            }
        }
        let showMenuBlock: (() -> Void)? = {
            self.showShadowView(true, animated: true)
            self.view.bringSubviewToFront((self.leftMenuViewController?.view)!)
            var contentFrame: CGRect = self.leftMenuViewController!.view.frame
            contentFrame.origin.x = 0
            self.leftMenuViewController?.view.frame = contentFrame
        }
        
        if (slideDelegate != nil) {
            slideDelegate?.willShowMenu(viewController: self)
        }
        notifyWillShowMenu()
        
        if animated {
            if self.boucing {
                showBouncingBlock!()
            } else {
                if let aBlock = showMenuBlock {
                    UIView.animate(withDuration: TimeInterval(animationDuration), animations: aBlock, completion: showMenuCompletionBlock)
                }
            }
        } else {
            showMenuBlock?()
            showMenuCompletionBlock!(true)
        }
    }
    
    func showLeftMenu(_ animated: Bool) {
        showMenu(self.leftMenuViewController!, animated: animated)
    }
    
    func notifyWillShowMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlideMenuWillShowNotification), object: self)
    }
    
    func notifyDidShowMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlideMenuDidShowNotification), object: self)
    }
    
    func notifyWillHideMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlideMenuWillHideNotification), object: self)
    }
    
    func notifyDidHideMenu() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlideMenuDidHideNotification), object: self)
    }
    
    func menuAbsoluteWidth() -> CGFloat {
        return CGFloat((menuWidth >= 0.0 && menuWidth <= 1.0) ? CGFloat(roundf(Float(menuWidth * view.bounds.size.width))) : menuWidth)
    }
    
    func showShadowView(_ isShow: Bool, animated: Bool) {
        DispatchQueue.main.async(execute: {
            if !isShow {
                self.isShowShadow = false
                if animated {
                    UIView.animate(withDuration: self.kSlideMenuDefaultAnimationDuration, animations: {
                        self.shadowView?.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                    }) { finished in
                        self.shadowView?.removeFromSuperview()
                    }
                } else {
                    self.shadowView?.removeFromSuperview()
                }
            } else {
                if self.isShowShadow || self.displayMenuSideBySide {
                    return
                }
                self.isShowShadow = true
                if animated {
                    self.contentContainerView?.addSubview(self.shadowView!)
                    UIView.animate(withDuration: self.kSlideMenuDefaultAnimationDuration, animations: {
                        self.shadowView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                    })
                } else {
                    self.contentContainerView?.addSubview(self.shadowView!)
                }
            }
        })
    }

    func switchLeftMenu(_ animated: Bool) {
        if menuViewVisible {
            hideMenu(animated)
        } else {
            showLeftMenu(animated)
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification?) {
        keyboardVisible = true
    }
    
    @objc func keyboardDidHide(_ notification: Notification?) {
        keyboardVisible = false
    }
    
    // MARK: - UIGestureRecognizerDelegate
    @IBAction func closeTapGestureRecognizerFired(_ sender: UIGestureRecognizer) {
        hideMenu(true)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // prevent recognizing touches on the slider
        var view: UIView? = touch.view
        while (view != nil) {
            if (view is UISlider) || (view is UISwitch) {
                return false
            }
            view = view?.superview
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return (gestureRecognizer != dragGestureRecognizer) || !(otherGestureRecognizer is UIPanGestureRecognizer)
    }

    func setSupportSwipeGesture(_ isSupportSwipeGesture: Bool)
    {
        if isSupportSwipeGesture && !(dragGestureRecognizer != nil)
        {
            if !(dragGestureRecognizer != nil)
            {
                let panGR = UIPanGestureRecognizer(target: self, action: #selector(dragGestureRecognizerDrag(_:)))
                panGR.delegate = (self as! UIGestureRecognizerDelegate)
                panGR.minimumNumberOfTouches = 1
                panGR.maximumNumberOfTouches = 1
                dragGestureRecognizer = panGR
                view.addGestureRecognizer(dragGestureRecognizer!)
            }
        }
        else
        {
            if (dragGestureRecognizer != nil)
            {
                view.removeGestureRecognizer(dragGestureRecognizer!)
                dragGestureRecognizer = nil
            }
        }
    }
    
    // MARK: - MenuHandling
    func delegateVetosDrag(withStart startPoint: CGPoint, end endPoint: CGPoint, inOrderToShowMenu isGoingToShowMenuWhenThisGestureSucceeds: Bool) -> Bool {
        return !slideDelegate!.shouldHandleSlideMenuGesture(viewController: self, startPonint: startPoint, endPoint: endPoint, isGoingToShowMenuWhenThisGestureSucceeds: isGoingToShowMenuWhenThisGestureSucceeds)
    }

    @objc func dragGestureRecognizerDrag(_ sender: UIPanGestureRecognizer) {
        if keyboardVisible || self.displayMenuSideBySide {
            return
        }
        
        let translation: CGPoint = sender.translation(in: leftMenuViewController!.view)
        let xTranslation: CGFloat = translation.x
        
        let state: UIGestureRecognizer.State = sender.state
        
        switch state {
        case .began:
            if !isShowShadow {
                contentContainerView?.addSubview(shadowView!)
            }
            dragContentStartX = (leftMenuViewController?.view.frame.origin.x)!
            dragGestureStartPoint = sender.location(in: view)
            break
        case .changed:
            let aView: UIView? = leftMenuViewController?.view
            var contentFrame: CGRect? = aView?.frame
            // Correct position
            var newStartX: CGFloat = dragContentStartX
            newStartX += xTranslation
            let endX = CGFloat((menuWidth >= 0.0 && menuWidth <= 1.0) ? CGFloat(roundf(Float(menuWidth * (contentFrame?.size.width ?? 0.0)))) : menuWidth)
            
            newStartX = min(newStartX, leftMenuViewController != nil ? endX : 0.0)
            if newStartX < 0 {
                contentFrame?.origin.x = newStartX
                aView?.frame = contentFrame ?? CGRect.zero
            }
            
            if abs(xTranslation) <= abs(endX) && newStartX < 0 && abs(Float(newStartX)) < abs(Float(endX)) {
                let alpha: CGFloat = (xTranslation > 0) ? xTranslation : endX + xTranslation
                shadowView?.backgroundColor = UIColor.black.withAlphaComponent(0.3 * alpha / endX)
            }
            break
        case .ended:
            if self.menuViewVisible {
                if abs(xTranslation) > menuWidth / 3 && xTranslation < 0 {
                    hideMenu(true)
                } else {
                    showLeftMenu(true)
                }
            } else {
                if abs(xTranslation) > menuWidth / 3 && xTranslation > 0 {
                    showLeftMenu(true)
                } else {
                    hideMenu(true)
                }
            }
            // Reset drag content start x
            dragContentStartX = 0.0
            dragGestureStartPoint = CGPoint.zero
            break
        default:
            break
        }
        
    }
    
    // Change content viewcontroller
    func switchViewController(_ viewController: UIViewController, animated: Bool) {
        let nav = self.contentViewController as! UINavigationController
        self.hideMenu(true)
        nav.setRootViewController(viewController, animated: animated)
    }
    
}
