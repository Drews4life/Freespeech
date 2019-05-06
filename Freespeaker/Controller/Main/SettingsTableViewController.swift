//
//  SettingsTableViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/18/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
    }
    
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    @IBAction func onLogOutClick(_ sender: Any) {
        FIRUser.logOutCurrentUser { [weak self] (success) in
            if success {
                let loginScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: WELCOME_VC)
                self?.present(loginScreen, animated: true, completion: nil)
            }
        }
    }
}
