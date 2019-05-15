//
//  GroupViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/11/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

class GroupViewController: UIViewController {
    
    @IBOutlet fileprivate weak var groupTitleTextField: UITextField!
    @IBOutlet fileprivate weak var groupImageView: UIImageView!
    @IBOutlet fileprivate weak var editBtn: UIButton!
    
    var group: NSDictionary!
    var groupIcon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(onSaveClick)),
            UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(onInviteClick))
        ]
        
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onGroupImageClick)))
        
        setupLayout()
    }
    
    fileprivate func setupLayout() {
        title = "Group"
        groupTitleTextField.text = group[kNAME] as? String
        
        imageFromData(pictureData: group[kAVATAR] as? String ?? "") { (image) in
            guard let image = image?.circleMasked else { return }
            self.groupImageView.image = image
        }
    }
    
    @objc fileprivate func onSaveClick() {
        guard let groupName = groupTitleTextField.text, groupName.count > 0 else { return }
        guard let avatarData = groupImageView.image?.jpegData(compressionQuality: 0.7) else { return }
        guard let groupID = group[kGROUPID] as? String else { return }
        let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        var valuesToUpdate: [String: Any] = [kNAME: groupName, kAVATAR: avatarString]
        Group.updateGroup(groupID: groupID, with: valuesToUpdate)
        
        valuesToUpdate = [kWITHUSERFULLNAME: groupName, kAVATAR: avatarString]
        
        ChatManager().updateExistingRecent(with: valuesToUpdate, for: groupID, withMembers: group[kMEMBERS] as? [String] ?? [])
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc fileprivate func onInviteClick() {
        guard let inviteUserVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: INVITE_USERS_VC) as? InviteUsersViewController else { return }
        inviteUserVC.group = group
        
        navigationController?.pushViewController(inviteUserVC, animated: true)
    }
    
    @objc fileprivate func onGroupImageClick() {
        showOptions()
    }
    
    @IBAction func onEditBtnClick(_ sender: Any) {
        showOptions()
    }
    
    fileprivate func showOptions() {
        let actionsMenu = UIAlertController(title: "Choose action", message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        let takePhoto = UIAlertAction(title: "Take or Choose Photo", style: .default) { (_) in
            
        }
        
        if let _ = groupIcon {
            let reset = UIAlertAction(title: "Reset", style: .destructive) { (_) in
                self.groupIcon = nil
                self.groupImageView.image = #imageLiteral(resourceName: "cameraIcon")
                self.editBtn.isHidden = true
            }
            actionsMenu.addAction(reset)
        }
        
        actionsMenu.addAction(cancel)
        actionsMenu.addAction(takePhoto)
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentController = actionsMenu.popoverPresentationController {
                currentPopoverpresentController.sourceView = editBtn
                currentPopoverpresentController.sourceRect = editBtn.bounds
                
                currentPopoverpresentController.permittedArrowDirections = .up
                
                present(actionsMenu, animated: true, completion: nil)
            }
        } else {
            present(actionsMenu, animated: true, completion: nil)
        }
    }
}
