//
//  NewGroupViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/9/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import ProgressHUD

class NewGroupViewController: UITableViewController, UISearchResultsUpdating, UserContactCellDelegate {
    
    fileprivate var users = [FIRUser]()
    fileprivate var matchedUser = [FIRUser]()
    fileprivate var filteredMatchedUsers = [FIRUser]()
    fileprivate var allUsersGrouped = [String: [FIRUser]]()
    fileprivate var sectionTitleList = [String]()
    
    fileprivate var memberIDsOfGroupChat = [String]()
    fileprivate var membersOfGroupChat = [FIRUser]()
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    var isGroup = true

    fileprivate lazy var contacts: [CNContact] = {
        let contactStore = CNContactStore()
        
        let keysToFetch: [Any] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey
        ]
        
        var allContainers = [CNContainer]()
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Could not get contacts with error: \(error.localizedDescription)")
        }
        
        var results = [CNContact]()
        allContainers.forEach({ (container) in
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResult = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResult)
            } catch {
                print("Could not fetch result for certain container with error: \(error.localizedDescription)")
            }
        })
        
        return results
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        title = "Contacts"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        
        setupButtons()
        loadUsers()
    }
    
    fileprivate func setupButtons() {
        var barButtons = [UIBarButtonItem]()
        
        if isGroup {
            let nextBtn = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(onNextClick))
            nextBtn.isEnabled = false
            
            barButtons.append(nextBtn)
        } else {
            let inviteBtn = UIBarButtonItem(image: #imageLiteral(resourceName: "invite"), style: .plain, target: self, action: #selector(onInviteClick))
            let searchBtn = UIBarButtonItem(image: #imageLiteral(resourceName: "location"), style: .plain, target: self, action: #selector(onSearchByNear))
            
            barButtons.append(searchBtn)
            barButtons.append(inviteBtn)
        }
        
        navigationItem.rightBarButtonItems = barButtons
    }
    
    @objc fileprivate func onNextClick() {
        guard let createGroupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: CREATE_NEW_GROUP_VC) as? CreateNewGroupViewController else { return }
        createGroupVC.allMembers = membersOfGroupChat
        createGroupVC.memberIDs = memberIDsOfGroupChat
        
        navigationController?.pushViewController(createGroupVC, animated: true)
    }
    
    @objc fileprivate func onInviteClick() {
        SettingsTableViewController.share(in: self)
    }
    
    @objc fileprivate func onSearchByNear() {
        
    }
    
    fileprivate func loadUsers() {
        ProgressHUD.show()
        reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { (snapshot, error) in
            ProgressHUD.dismiss()
            if let err = error {
                print("Could not fetch user with error: \(err.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                self.matchedUser = []
                self.users = []
                
                snapshot.documents.forEach({ (userData) in
                    let userDictionary = userData.data() as NSDictionary
                    let newUser = FIRUser(_dictionary: userDictionary)
                    if newUser.objectId != FIRUser.currentId() {
                        self.users.append(newUser)
                    }                })
                
                self.tableView.reloadData()
            }
            
            self.compareUsers()
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count > 0 else {
            tableView.reloadData()
            return
        }
        
        filterBy(searchText: searchText)
    }
    
    func filterBy(searchText: String, scope: String = "All") {
        filteredMatchedUsers = matchedUser.filter { $0.firstname.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    func didClickProfileImage(at indexPath: IndexPath) {
        guard let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
        var user: FIRUser
        
        if isSearching() {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let section = sectionTitleList[indexPath.section]
            user = allUsersGrouped[section]![indexPath.row]
        }
        
        profileVC.user = user
        
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sectionTitleList[indexPath.section]
        let user = isSearching() ? filteredMatchedUsers[indexPath.row] : allUsersGrouped[section]![indexPath.row]
        
        if !isGroup {
            if !checkUserBlockedStatus(with: user) {
                let chatVC = ChatViewController.populateSingleChat(withUser: user)
                navigationController?.pushViewController(chatVC, animated: true)
            } else {
                ProgressHUD.showError("You are blacklisted by this user")
            }
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }
            
            let selected = memberIDsOfGroupChat.contains(user.objectId)
            
            if selected {
                if let indx = memberIDsOfGroupChat.firstIndex(of: user.objectId) {
                    memberIDsOfGroupChat.remove(at: indx)
                    membersOfGroupChat.remove(at: indx)
                }
            } else {
                memberIDsOfGroupChat.append(user.objectId)
                membersOfGroupChat.append(user)
            }
            
            navigationItem.rightBarButtonItem?.isEnabled = memberIDsOfGroupChat.count > 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching() ? 1 : allUsersGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching() {
            return filteredMatchedUsers.count
        } else {
            let sectionTitle = sectionTitleList[section]
            let usersForSection = allUsersGrouped[sectionTitle]
            
            return usersForSection?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearching() ? "" : sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearching() ? nil : sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: USER_CONTACT_CELL, for: indexPath) as? UserContactCell else { return UITableViewCell() }
        
        var user: FIRUser
        
        if isSearching() {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let section = sectionTitleList[indexPath.section]
            let usersForSection = allUsersGrouped[section]
            user = usersForSection![indexPath.row]
        }
        
        cell.delegate = self
        cell.setupCell(withUser: user, forPath: indexPath)
        
        return cell
    }
    
    fileprivate func compareUsers() {
        users.forEach { (user) in
            if user.phoneNumber != "" {
                let contact = searchForContact(withNum: user.phoneNumber)
                if contact.count > 0 {
                    print("added matched user:\(user.fullname)")
                    matchedUser.append(user)
                }
                
                
            }
        }
        self.tableView.reloadData()
        splitDataIntoSections()
    }
    
    fileprivate func searchForContact(withNum phoneNumber: String) -> [CNContact] {
        var results = [CNContact]()
        
        contacts.forEach { (contact) in
            if !contact.phoneNumbers.isEmpty {
                let compareAgainstNum = updatePhoneNumber(withNum: phoneNumber, replacePlusSign: true)
                contact.phoneNumbers.forEach({ (phoneNumberCN) in
                    let fullMobileNum = phoneNumberCN.value
                    let countryCode = fullMobileNum.value(forKey: "countryCode") as? String
                    let phoneNumberLocal = fullMobileNum.value(forKey: "digits") as? String
                    
                    let contactNumber = removeCountryCode(codeLetters: countryCode ?? "", fullPhoneNumber: phoneNumberLocal ?? "")
                    
                    if contactNumber == compareAgainstNum {
                        results.append(contact)
                    }
                })
            }
        }
        
        
        return results
    }
    
    fileprivate func updatePhoneNumber(withNum phoneNumber: String, replacePlusSign: Bool) -> String {
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }
    
    fileprivate func removeCountryCode(codeLetters: String, fullPhoneNumber: String) -> String {
        let countryCode = CountryCode()
        guard let countryCodeToRemove = countryCode.codeDictionaryShort[codeLetters.uppercased()] else { return "" }
        let updatedCode = updatePhoneNumber(withNum: countryCodeToRemove, replacePlusSign: true)
        let replacedNumber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        return replacedNumber
    }
    
    fileprivate func splitDataIntoSections() {
        var sectionTitle = ""
        
        for i in 0..<matchedUser.count {
            let currentUser = matchedUser[i]
            let firstChar = currentUser.firstname.first
            let firstCharString = ("\(firstChar ?? " ")").uppercased()
            
            if firstCharString != sectionTitle {
                sectionTitle = firstCharString
                if let occurance = allUsersGrouped[firstCharString], occurance.count > 0 {
                    allUsersGrouped[sectionTitle]?.append(currentUser)
                } else {
                    allUsersGrouped[sectionTitle] = [currentUser]
                    sectionTitleList.append(sectionTitle)
                }
            } else {
                allUsersGrouped[firstCharString]?.append(currentUser)
            }
        }
        tableView.reloadData()
    }
    
    fileprivate func isSearching() -> Bool {
        return searchController.isActive && searchController.searchBar.text != ""
    }
}
