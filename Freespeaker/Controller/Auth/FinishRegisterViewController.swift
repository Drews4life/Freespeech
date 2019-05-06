//
//  ProfileViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/16/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

protocol FinishRegisterDelegate {
    func didFinishRegister()
}

class FinishRegisterViewController: UIViewController {
    
    @IBOutlet fileprivate weak var nameTextField: UITextField!
    @IBOutlet fileprivate weak var surnameTextField: UITextField!
    @IBOutlet fileprivate weak var countryTextField: UITextField!
    @IBOutlet fileprivate weak var cityTextField: UITextField!
    @IBOutlet fileprivate weak var phoneTextField: UITextField!
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    
    var email: String!
    var password: String!
    var profileImage: UIImage?
    
    var delegate: FinishRegisterDelegate?
    
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
        if let error = validateForm() {
            ProgressHUD.showError(error)
        } else {
            ProgressHUD.show("Please wait...")
            
            FIRUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { [weak self] (error) in
                if let err = error {
                    ProgressHUD.dismiss()
                    debugPrint("Error occured: \(err.localizedDescription)")
                    ProgressHUD.showError("Could not register")
                } else {
                    self?.registerUser()
                }
            }
        }
    }
    
    fileprivate func registerUser() {
        let fullname = "\(nameTextField.text!) \(surnameTextField.text!)"
        var tempDictionary: [String: Any] = [
            kFIRSTNAME: nameTextField.text!,
            kLASTNAME: surnameTextField.text!,
            kFULLNAME: fullname,
            kCOUNTRY: countryTextField.text!,
            kCITY: cityTextField.text!,
            kPHONE: phoneTextField.text!
        ]
        
        if let profileImg = profileImage {
            guard let profileImgData = profileImg.jpegData(compressionQuality: 0.8) else { return }
            let profileImgBase64 = profileImgData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            tempDictionary[kAVATAR] = profileImgBase64
        } else {
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!) { (image) in
                guard let profileImgData = image.jpegData(compressionQuality: 0.8) else { return }
                let profileImgBase64 = profileImgData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDictionary[kAVATAR] = profileImgBase64
            }
        }
        
        self.finishRegisterProcess(withDictionary: tempDictionary)
    }
    
    fileprivate func finishRegisterProcess(withDictionary dictionary: [String: Any]) {
        updateCurrentUserInFirestore(withValues: dictionary) { (error) in
            ProgressHUD.dismiss()
            if let err = error {
                debugPrint("Could not update user: \(err.localizedDescription)")
                ProgressHUD.showError("Could not save user")
            } else {
                self.clearAllInputs()
                NotificationCenter.default.post(name: USER_DID_LOGIN_NOTIFICATION, object: nil, userInfo: [kUSERID: FIRUser.currentId()])
                
                self.navigationController?.popViewController(animated: false)
                self.delegate?.didFinishRegister()
//                self.present(mainApplication, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func validateForm() -> String? {
        guard let name = nameTextField.text, name.count > 0 else {
            return "Enter your name"
        }
        guard let surname = surnameTextField.text, surname.count > 0 else {
            return "Enter your surname"
        }
        guard let country = countryTextField.text, country.count > 0 else {
            return "Enter your country"
        }
        guard let city = cityTextField.text, city.count > 0 else {
            return "Enter your city"
        }
        guard let phone = phoneTextField.text, phone.count > 0 else {
            return "Enter your phone number"
        }
        
        return nil
    }
    
    fileprivate func clearAllInputs() {
        nameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
        surnameTextField.text = ""
        profileImageView.image = #imageLiteral(resourceName: "avatarPlaceholder")
    }
}
