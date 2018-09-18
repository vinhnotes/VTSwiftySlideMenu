//
//  ViewController.swift
//  VTSwiftySlideMenu
//
//  Created by whatsltd4us on 09/14/2018.
//  Copyright (c) 2018 whatsltd4us. All rights reserved.
//

import UIKit
import VTSwiftySlideMenu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        update(super.traitCollection)
    }

    func update(_ trailCollection: UITraitCollection)  {
        if (SizeClassHelper.isWideScreen(trailCollection))
        {
            self.setupLeftBarButton(false)
        }
        else
        {
            self.setupLeftBarButton(true)
        }
    }
    
    func setupLeftBarButton(_ showMenu: Bool) {
        if (showMenu)
        {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: #imageLiteral(resourceName: "MenuIcon"), style: .done, target: self, action: #selector(showLeftMenu))
        }
        else
        {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc func showLeftMenu() {
        self.view.endEditing(true)
        self.slideMenuViewController().showLeftMenu(true)
    }

}

