//
//  BlockedUserViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/8/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

class BlockedUserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserContactCellDelegate {
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var messageLbl: UILabel!
    
    var blockedUsers = [FIRUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        navigationItem.largeTitleDisplayMode = .never
        
        loadBlockedUser()
    }
    
    fileprivate func loadBlockedUser() {
        guard let localBlockedUsers = FIRUser.currentUser()?.blockedUsers, localBlockedUsers.count > 0 else { return }
        ProgressHUD.show()
        
        getUsersFromFirestore(withIds: localBlockedUsers) { (users) in
            ProgressHUD.dismiss()
            self.blockedUsers = users
            self.tableView.reloadData()
        }
    }
    
    func didClickProfileImage(at indexPath: IndexPath) {
        guard let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
        profileVC.user = blockedUsers[indexPath.row]
        
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unblock"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard var tempBlocked = FIRUser.currentUser()?.blockedUsers else { return }
        let userIdToUnblock = blockedUsers[indexPath.row].objectId
        
        tempBlocked = tempBlocked.filter{ $0 != userIdToUnblock }
        blockedUsers.remove(at: indexPath.row)
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: tempBlocked]) { (error) in
            if let err = error {
                print("Could not block user with error: \(err.localizedDescription)")
            }
            
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageLbl.isHidden = blockedUsers.count > 0
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: USER_CONTACT_CELL, for: indexPath) as? UserContactCell else { return UITableViewCell() }
        
        cell.delegate = self
        cell.setupCell(withUser: blockedUsers[indexPath.row], forPath: indexPath)
        
        return cell
    }
}
