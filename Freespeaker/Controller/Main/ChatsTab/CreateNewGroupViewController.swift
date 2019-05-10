//
//  CreateNewGroupViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/10/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

class CreateNewGroupViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, GroupMemberCellDelegate {
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var editBtn: UIButton!
    @IBOutlet fileprivate weak var groupImageView: UIImageView!
    @IBOutlet fileprivate weak var groupTitleTextField: UITextField!
    @IBOutlet fileprivate weak var participantsLbl: UILabel!
    
    var memberIDs = [String]()
    var allMembers = [FIRUser]()
    var groupIcon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createGroup))
        
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onNewGroupImageClick)))
        
        updateParticipantsLbl()
    }
    
    
    @objc fileprivate func createGroup() {
        guard let groupName = groupTitleTextField.text, groupName.count > 0 else {
            ProgressHUD.showError("Group name cannot be empty");
            return
        }
        guard let groupImageData = UIImage(named: "groupIcon")?.jpegData(compressionQuality: 0.7) else { return }
        memberIDs.append(FIRUser.currentId())
        var avatar = groupImageData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        if let groupIcon = groupIcon {
            let avatarData = groupIcon.jpegData(compressionQuality: 0.7)
            if let data = avatarData {
                avatar = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
        }
        
        let groupID = UUID().uuidString
        
        let group = Group(groupID: groupID, subject: groupName, ownerID: FIRUser.currentId(), members: memberIDs, avatar: avatar)
        group.saveGroup()
        
        let chatVC = ChatViewController.populateGroupChat(withGroup: group)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    @objc fileprivate func onNewGroupImageClick() {
    
    }
    
    func didClickCancel(at indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIDs.remove(at: indexPath.row)
        
        collectionView.reloadData()
        updateParticipantsLbl()
    }
    
    @IBAction func onEditBtnClick(_ sender: UIButton) {
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
    
//    fileprivate func
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GROUP_MEMBER_CELL, for: indexPath) as? GroupMemberCell else { return UICollectionViewCell() }
        
        cell.delegate = self
        cell.setupCell(user: allMembers[indexPath.row], indexPath: indexPath)
        
        return cell
    }
    
    fileprivate func updateParticipantsLbl() {
        participantsLbl.text = "Participants: \(allMembers.count)"
        
        navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
    }
}
