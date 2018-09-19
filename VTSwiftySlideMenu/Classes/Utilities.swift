//
//  Utilities.swift
//  Pods-VTSwiftySlideMenu_Example
//
//  Created by Vu Dinh Vinh on 9/14/18.
//

import UIKit

class Utilities: NSObject
{
    // check iPad Pro
    class func isIPadPro() -> Bool
    {
        return (isIPad()
            && (UIScreen.main.bounds.size.height == 1366 || UIScreen.main.bounds.size.width == 1366))
    }
    
    // check iPad
    class func isIPad() -> Bool
    {
        return (UIDevice.current.userInterfaceIdiom == .pad)
    }
    
    class func animateTransitionController(_ controller: UIViewController?, duration: CGFloat, withType type: String?) {
        let transition = CATransition()
        transition.duration = CFTimeInterval(duration)
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType(rawValue: type ?? "")
        controller?.view.layer.add(transition, forKey: nil)
    }
}
