//
//  ProfileViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/16/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit


class FinishRegisterViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var email: String!
    var password: String!
    var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func onCancelClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onDoneClick(_ sender: Any) {
        print("everything is ok")
    }
    
}
