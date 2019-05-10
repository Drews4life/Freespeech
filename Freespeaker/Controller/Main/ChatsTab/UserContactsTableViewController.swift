//
//  UserContactsTableViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/18/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UserContactsTableViewController: UITableViewController, UISearchResultsUpdating, UserContactCellDelegate {
    
    @IBOutlet fileprivate weak var subHeaderView: UIView!
    @IBOutlet fileprivate weak var filterSegmentedControl: UISegmentedControl!
    
    fileprivate var allUsers = [FIRUser]()
    fileprivate var filteredUsers = [FIRUser]()
    fileprivate var allUsersGrouped = [String: [FIRUser]]()
    fileprivate var sectionTitleList = [String]()
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableFooterView = UIView()
        
        loadUsers(filter: kCITY)
    }
    
    @IBAction func onSegmentFilterChange(_ sender: UISegmentedControl) {
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
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count > 0 else {
            tableView.reloadData()
            return
        }
        filterContentForSearch(searchText: searchText)
    }
    
    fileprivate func filterContentForSearch(searchText: String, scope: String = "All") {
        filteredUsers = allUsers.filter{ $0.firstname.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        }
        
        return allUsersGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        
        let sectionTitle = sectionTitleList[section]
    
        return allUsersGrouped[sectionTitle]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }
        
        return sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        }
        
        return sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let user = getUserWithCondition(at: indexPath) else { return }
        guard let currentUser = FIRUser.currentUser() else { return }
        
        if !checkUserBlockedStatus(with: user) {
            let chatVC = ChatViewController.populateSingleChat(withUser: user)
            
            navigationController?.pushViewController(chatVC, animated: true)
        } else {
            ProgressHUD.showError("You are blacklisted by this user.")
        }
    }
    
    func didClickProfileImage(at indexPath: IndexPath) {
        let user = getUserWithCondition(at: indexPath)
        
        guard let userProfileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
        userProfileVC.user = user
        
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: USER_CONTACT_CELL, for: indexPath) as? UserContactCell else { return UITableViewCell() }
        
        guard let user = getUserWithCondition(at: indexPath) else { return UITableViewCell() }
        
        cell.setupCell(withUser: user, forPath: indexPath)
        cell.delegate = self
        
        return cell
    }
    
    fileprivate func getUserWithCondition(at indexPath: IndexPath) -> FIRUser? {
        var user: FIRUser?
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionString = sectionTitleList[indexPath.section]
            user = allUsersGrouped[sectionString]?[indexPath.row]
        }
        
        return user
    }
}
