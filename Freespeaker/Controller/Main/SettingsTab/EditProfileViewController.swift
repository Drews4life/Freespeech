//
//  EditProfileViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/8/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

class EditProfileViewController: UIViewController {
    
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    @IBOutlet fileprivate weak var nameTextField: UITextField!
    @IBOutlet fileprivate weak var surnameTextField: UITextField!
    @IBOutlet fileprivate weak var emailTextField: UITextField!
    
    fileprivate var pickedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(save))
        
        setupLayout()
    }
    
    fileprivate func setupLayout() {
        guard let currentUser = FIRUser.currentUser() else { return }
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeProfileImage)))
        
        nameTextField.text = currentUser.firstname
        surnameTextField.text = currentUser.lastname
        emailTextField.text = currentUser.email
        
        if currentUser.avatar.count > 0 {
            imageFromData(pictureData: currentUser.avatar) { (image) in
                guard let image = image?.circleMasked else { return }
                self.profileImageView.image = image
            }
        }
    }
    
    @objc fileprivate func save() {
        guard let name = nameTextField.text, name.count > 0 else { ProgressHUD.showError(); return }
        guard let surname = surnameTextField.text, surname.count > 0 else { ProgressHUD.showError(); return }
        guard let email = emailTextField.text, email.count > 0 else { ProgressHUD.showError(); return }
        navigationItem.rightBarButtonItem?.isEnabled = false
        ProgressHUD.show("Saving")
        
        let fullname = "\(name) \(surname)"
        var values = [kFIRSTNAME: name, kLASTNAME: surname, kFULLNAME: fullname, kEMAIL: email]
        
        if let newImage = pickedImage {
            if let profileImageData = newImage.jpegData(compressionQuality: 0.7) {
                let profileImageBase64 = profileImageData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                values[kAVATAR] = profileImageBase64
            }
        }
        
        updateCurrentUserInFirestore(withValues: values) { (error) in
            ProgressHUD.dismiss()
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            if let err = error {
                ProgressHUD.showError("Could not update profile")
                print("Could not update user profile: \(err.localizedDescription)")
            }
        }
    }
    
    @objc fileprivate func changeProfileImage() {
    
    }
}
