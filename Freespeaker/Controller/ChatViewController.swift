//
//  ViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/13/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase

class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }

}
