//
//  InviteUsersViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/12/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class InviteUsersViewController: UITableViewController, UserContactCellDelegate {
    
    @IBOutlet fileprivate weak var headerView: UIView!
    
    fileprivate var allUsers = [FIRUser]()
    fileprivate var allUsersGrouped = [String: [FIRUser]]()
    fileprivate var sectionTitleList = [String]()
    
    var newMembersIDs = [String]()
    var currentMemberIDs = [String]()
    var group: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Users"
        tableView.tableFooterView = UIView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(onDoneBtnClick))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        if let members = group[kMEMBERS] as? [String] {
            currentMemberIDs = members
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        loadUsers(filter: kCITY)
    }
    
    @objc fileprivate func onDoneBtnClick() {
        updateGroup()
    }
    
    fileprivate func updateGroup() {
        let manager = ChatManager()
        let tempMemb = currentMemberIDs + newMembersIDs
        let tempMembToPush = group[kMEMBERSTOPUSH] as! [String] + newMembersIDs
        let groupID = group[kGROUPID] as! String
        let groupName = group[kNAME] as! String
        let groupAvatar = group[kAVATAR] as? String
        
        let valuesToChange = [kMEMBERSTOPUSH: tempMembToPush, kMEMBERS: tempMemb]
        
        Group.updateGroup(groupID: groupID, with: valuesToChange)
        
        manager.createRecentForNewMembers(groupID: groupID, groupName: groupName, membersToPush: tempMembToPush, avatar: groupAvatar ?? "")
        manager.updateExistingRecent(with: valuesToChange, for: groupID, withMembers: tempMemb)
        goToGroupChat(membersToPush: tempMembToPush, members: tempMemb)
    }
    
    fileprivate func goToGroupChat(membersToPush: [String], members: [String]) {
        let chatVC = ChatViewController()
        chatVC.titleHeader = group[kNAME] as? String ?? ""
        chatVC.membersToPush = group[kMEMBERSTOPUSH] as? [String] ?? []
        chatVC.memberIDs = group[kMEMBERS] as? [String] ?? []
        chatVC.chatroomID = group[kGROUPID] as? String ?? ""
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    fileprivate func loadUsers(filter: String) {
        guard let currentUser = FIRUser.currentUser() else { return }
        var query: Query!
        
        ProgressHUD.show()
        
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: currentUser.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: currentUser.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            ProgressHUD.dismiss()
            if let err = error {
                debugPrint("Could not get contacts: \(err.localizedDescription)")
                return
            }
            
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGrouped = [:]
            
            guard let usersDictionary = snapshot?.documents else { return }
            
            usersDictionary.forEach({ (userSnapshot) in
                let singleUserDictionary = userSnapshot.data() as NSDictionary
                let user = FIRUser(_dictionary: singleUserDictionary)
                
                if user.objectId != FIRUser.currentId() {
                    self.allUsers.append(user)
                }
            })
            
            self.splitDataIntoSections()
            self.tableView.reloadData()
        }
    }
    
    fileprivate func splitDataIntoSections() {
        var sectionTitle = ""
        
        for i in 0..<allUsers.count {
            let currentUser = allUsers[i]
            
            if let firstChar = currentUser.firstname.first {
                let firstCharString = "\(firstChar)"
                
                if firstCharString != sectionTitle {
                    if let groupforSection = allUsersGrouped[firstCharString.uppercased()], groupforSection.count > 0 {
                        allUsersGrouped[firstCharString.uppercased()]?.append(currentUser)
                    } else {
                        sectionTitle = firstCharString
                        allUsersGrouped[sectionTitle] = []
                        sectionTitleList.append(sectionTitle)
                        
                        allUsersGrouped[firstCharString]?.append(currentUser)
                    }
                }
            }
        }
    }
    
    func didClickProfileImage(at indexPath: IndexPath) {
        let section = sectionTitleList[indexPath.section]
        guard let user = allUsersGrouped[section]?[indexPath.row] else { return }
        
        guard let userProfileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
        userProfileVC.user = user
        
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    @IBAction func onSegmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                loadUsers(filter: kCITY)
            case 1:
                loadUsers(filter: kCOUNTRY)
            case 2:
                loadUsers(filter: "")
            default:
                break;
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = sectionTitleList[indexPath.section]
        guard let user = allUsersGrouped[section]?[indexPath.row] else { return }
        
        if currentMemberIDs.contains(user.objectId) {
            ProgressHUD.showError("User already in group")
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = cell.accessoryType == .checkmark ? .none : .checkmark
        }
        
        let selected = newMembersIDs.contains(user.objectId)
        
        if selected {
            newMembersIDs = newMembersIDs.filter{ $0 != user.objectId }
        } else {
            newMembersIDs.append(user.objectId)
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = newMembersIDs.count > 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allUsersGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sectionTitleList[section]
        return allUsersGrouped[section]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: USER_CONTACT_CELL, for: indexPath) as? UserContactCell else { return UITableViewCell() }
        
        let section = sectionTitleList[indexPath.section]
        guard let user = allUsersGrouped[section]?[indexPath.row] else { return UITableViewCell() }
        
        cell.setupCell(withUser: user, forPath: indexPath)
        cell.delegate = self
        
        return cell
    }
}
