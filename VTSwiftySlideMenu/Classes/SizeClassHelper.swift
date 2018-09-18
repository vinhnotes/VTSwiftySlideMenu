//
//  SizeClassHelper.swift
//  Pods-VTSwiftySlideMenu_Example
//
//  Created by Vu Dinh Vinh on 9/14/18.
//

import UIKit

enum SizeClassType
{
    case PhoneLandscape;
    case PhonePortrait;
    case PadLandscape;
    case PadPortrait;
    case SplitLandscapeWide;
    case SplitLandscape;
    case SplitPortrait;
    case PhoneLandscapeWide;
}

class SizeClassHelper: NSObject
{
    class func trailToString(_ trailCollection: UITraitCollection) -> SizeClassType
    {
        var classType = SizeClassType.PhonePortrait
        let appSise = UIApplication.shared.windows.first?.bounds.size
        let screenSize = UIScreen.main.bounds.size
        switch trailCollection.userInterfaceIdiom
        {
            case .phone:
                if (screenSize.width > screenSize.height)
                {
                    classType = (screenSize.width >= 896) ? .PhoneLandscapeWide : .PhoneLandscape
                }
                else
                {
                    classType = .PhonePortrait
                }
                break
            case .pad:
                if (screenSize.width > screenSize.height)
                {
                    classType = .PadLandscape
                }
                else
                {
                    classType = .PadPortrait
                }
            default:
                break
        }
        if !__CGSizeEqualToSize(appSise!, screenSize)
        {
            if (screenSize.width > screenSize.height)
            {
                if !((appSise?.width)! < screenSize.width / 2.0)
                {
                    classType = .SplitLandscapeWide
                }
                else
                {
                    classType = .SplitLandscape
                }
            }
            else
            {
                classType = .SplitPortrait
            }
        }
        return classType
    }
    
    class func isWideScreen(_ trailCollection: UITraitCollection) -> Bool {
        return (SizeClassHelper.trailToString(trailCollection) != .SplitPortrait
            && SizeClassHelper.trailToString(trailCollection) != .SplitLandscape
            && SizeClassHelper.trailToString(trailCollection) != .PhoneLandscape
            && SizeClassHelper.trailToString(trailCollection) != .PhonePortrait)
    }
}
