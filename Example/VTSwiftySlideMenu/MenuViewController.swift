//
//  MenuViewController.swift
//  VTSwiftySlideMenu_Example
//
//  Created by Vu Dinh Vinh on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let home = self.storyboard?.instantiateViewController(withIdentifier: "Home")
            self.slideMenuViewController().switchViewController(home!, animated: true)
            break
        case 1:
            let others = self.storyboard?.instantiateViewController(withIdentifier: "Others")
            others?.title = "Others"
            self.slideMenuViewController().switchViewController(others!, animated: true)
            break
        default:
            break
        }
    }

}
