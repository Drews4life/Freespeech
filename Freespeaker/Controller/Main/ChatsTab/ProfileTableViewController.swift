//
//  ProfileTableViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/19/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfileTableViewController: UITableViewController {
    
    @IBOutlet fileprivate weak var fullnameLbl: UILabel!
    @IBOutlet fileprivate weak var phoneNumberLbl: UILabel!
    @IBOutlet fileprivate weak var userProfileImageView: UIImageView!
    @IBOutlet fileprivate weak var callBtn: UIButton!
    @IBOutlet fileprivate weak var messageBtn: UIButton!
    @IBOutlet fileprivate weak var blockBtn: UIButton!
    
    var user: FIRUser?
    
    deinit {
        print("WE LEFT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
    }
    
    fileprivate func setupLayout() {
        guard let user = user else { return }
        
        title = "Profile"
        fullnameLbl.text = user.fullname
        phoneNumberLbl.text = user.phoneNumber
        
        checkBlockStatus()
        
        imageFromData(pictureData: user.avatar) { (image) in
            guard let userImage = image?.circleMasked else { return }
            self.userProfileImageView.image = userImage
        }
        
        tableView.tableFooterView = UIView()
    }
    
    fileprivate func checkBlockStatus() {
        guard let user = user else { return }
        
        if user.objectId == FIRUser.currentId() {
            blockBtn.isHidden = true
            messageBtn.isHidden = true
            callBtn.isHidden = true
        }
        
        if let currentUser = FIRUser.currentUser() {
            if currentUser.blockedUsers.contains(user.objectId) {
                blockBtn.setTitle("Unblock", for: .normal)
            } else {
                blockBtn.setTitle("Block", for: .normal)
            }
        }
    }
    
    @IBAction func onCallBtnClick(_ sender: Any) {
        
    }
    
    @IBAction func onMessageBtnClick(_ sender: Any) {
        
    }
    
    @IBAction func onBlockUserClick(_ sender: Any) {
        guard let currentUser = FIRUser.currentUser() else { return }
        guard let userToBlock = user else { return }
        
        var currentlyBlockedUserIDs = currentUser.blockedUsers
        
        if currentlyBlockedUserIDs.contains(userToBlock.objectId) {
            currentlyBlockedUserIDs = currentlyBlockedUserIDs.filter{ $0 != userToBlock.objectId }
        } else {
            currentlyBlockedUserIDs.append(userToBlock.objectId)
        }
        
        ProgressHUD.show()
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: currentlyBlockedUserIDs]) { (error) in
            ProgressHUD.dismiss()
            if let err = error {
                ProgressHUD.showError("Unable to block user")
                debugPrint("Could not block user with error \(err.localizedDescription)")
            } else {
                self.checkBlockStatus()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
            case 0:
                return 0
            default:
                return 30
        }
    }
}
