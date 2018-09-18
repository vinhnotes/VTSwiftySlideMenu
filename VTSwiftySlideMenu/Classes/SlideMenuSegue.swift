//
//  SlideMenuSegue.swift
//  Pods-VTSwiftySlideMenu_Example
//
//  Created by Vu Dinh Vinh on 9/14/18.
//

import UIKit

class SlideMenuLeftSegue: UIStoryboardSegue
{
    override func perform()
    {
        let slideMenuViewController = self.source
        let leftMenuViewController = self.destination
        (slideMenuViewController as! SlideMenuViewController).setLeftMenu(leftMenuViewController)
    }
}

class  SlideMenuContentSegue: UIStoryboardSegue
{
    override func perform() {
        let slideMenuViewController = self.source
        let contentViewController = self.destination
        (slideMenuViewController as! SlideMenuViewController).setContentViewController(contentViewController, animated: true)
    }
}
