//
//  ViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/13/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class WelcomeViewController: UIViewController, FinishRegisterDelegate {
    
    @IBOutlet fileprivate weak var emailTextField: UITextField!
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    @IBOutlet fileprivate weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
    }
    
    @IBAction func onLoginBtnClick(_ sender: Any) {
        guard let email = emailTextField.text, email.count > 0 else {
            ProgressHUD.showError("Email cannot be empty")
            return
        }
        guard let password = passwordTextField.text, password.count > 0 else {
            ProgressHUD.showError("Password cannot be empty")
            return
        }
        dismissKeyboard()
        ProgressHUD.show()
        
        FIRUser.loginUserWith(email: email, password: password) { [weak self] (error) in
            ProgressHUD.dismiss()
            if let err = error {
                debugPrint("Could not login user: \(err.localizedDescription)")
                return
            }
            
            self?.procceedToMainApplication()
        }
    }
    
    
    @IBAction func onRegisterBtnClick(_ sender: Any) {
        guard let email = emailTextField.text, email.count > 0 else {
            ProgressHUD.showError("Email cannot be empty")
            return
        }
        guard let password = passwordTextField.text, password.count > 0 else {
            ProgressHUD.showError("Password cannot be empty")
            return
        }
        guard let repeatPassword = repeatPasswordTextField.text, repeatPassword == password else {
            ProgressHUD.showError("Confirmation password must match")
            return
        }
        dismissKeyboard()
        
        guard let finalFormViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: FINAL_FORM_VC) as? FinishRegisterViewController else { return }
        finalFormViewController.email = email
        finalFormViewController.password = password
        finalFormViewController.delegate = self
        
        navigationController?.pushViewController(finalFormViewController, animated: true)
        clearAllFields()
    }
    
    func didFinishRegister() {
        procceedToMainApplication()
    }
    
    
    fileprivate func procceedToMainApplication() {
        clearAllFields()
        dismissKeyboard()
        
        guard let mainApplication = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: MAIN_APPLICATION_ID) as? UITabBarController else { return }
        
        NotificationCenter.default.post(name: USER_DID_LOGIN_NOTIFICATION, object: nil, userInfo: [kUSERID: FIRUser.currentId()])
        
        present(mainApplication, animated: true, completion: nil)
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }

    fileprivate func clearAllFields() {
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
}
