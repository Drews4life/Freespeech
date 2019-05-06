//
//  ChatsViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/18/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class RecentChatsViewController: UIViewController, RecentChatCellDelegate {
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var recentChats = [NSDictionary]()
    fileprivate var filteredChats = [NSDictionary]()
    fileprivate var recentChatsListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()

        navigationItem.searchController = searchController
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        loadChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        recentChatsListener?.remove()
    }
    
    fileprivate func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        let buttonContainer = UIView(frame: CGRect(x: 0, y: 5, width: view.frame.width, height: 40))
        let newGropBtn = UIButton(type: .system)
        
        newGropBtn.frame = CGRect(x: view.frame.width - 110, y: 10, width: 100, height: 20)
        newGropBtn.setTitle("New Group", for: .normal)
        newGropBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        newGropBtn.addTarget(self, action: #selector(onNewGroupClick), for: .touchUpInside)
        
        let separator = UIView(frame: CGRect(x: 0, y: header.frame.height - 1, width: view.frame.width, height: 1))
        separator.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        buttonContainer.addSubview(newGropBtn)
        header.addSubview(buttonContainer)
        header.addSubview(separator)
        
        tableView.tableHeaderView = header
    }
    
    @objc fileprivate func onNewGroupClick() {
        
    }
    
    @IBAction func onCreateNewChatClick(_ sender: Any) {
        let contactsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_CONTACTS_VC)
        
        navigationController?.pushViewController(contactsVC, animated: true)
    }
    
    fileprivate func loadChats() {
        recentChatsListener = reference(.Recent).whereField(kUSERID, isEqualTo: FIRUser.currentId()).addSnapshotListener({ (snapshot, error) in
            if let err = error {
                debugPrint("Error occured while listening for chats: \(err.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            self.recentChats = []
            
            if !snapshot.isEmpty {
                guard let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as? [NSDictionary]) else { return }
                
                sorted.forEach({ (recent) in
                    if let recentLastMsg = recent[kLASTMESSAGE] as? String {
                        if recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                            self.recentChats.append(recent)
                        }
                    }
                })
                
                self.tableView.reloadData()
            }
        })
    }
    
    func onAvatarClick(at indexPath: IndexPath) {
        let recent = getRecentChatWithCondition(at: indexPath)
        
        guard let recentType = recent[kTYPE] as? String, recentType == kPRIVATE else { return }
        guard let userID = recent[kWITHUSERUSERID] as? String else { return }
        
        ProgressHUD.show()
        reference(.User).document(userID).getDocument { (snapshot, error) in
            ProgressHUD.dismiss()
            if let err = error {
                debugPrint("Could not get user with error: \(err.localizedDescription)")
                return
            }
            guard let userDictionary = snapshot?.data() as NSDictionary? else { return }
            let clickedUser = FIRUser(_dictionary: userDictionary)
            
            guard let userProfileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
            userProfileVC.user = clickedUser
            
            
            self.navigationController?.pushViewController(userProfileVC, animated: true)
        }
    }
    
    fileprivate func getRecentChatWithCondition(at indexPath: IndexPath) -> NSDictionary {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats[indexPath.row]
        }
        return recentChats[indexPath.row]
    }
    
}


extension RecentChatsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recent = getRecentChatWithCondition(at: indexPath)
        ChatManager().restartRecentChat(recent: recent)
        
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.chatroomID = recent[kCHATROOMID] as? String
        chatVC.memberIDs = recent[kMEMBERS] as? [String]
        chatVC.membersToPush = recent[kMEMBERSTOPUSH] as? [String]
        chatVC.titleHeader = recent[kWITHUSERFULLNAME] as? String
        chatVC.isGroup = recent[kTYPE] as? String == kGROUP
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let recent = getRecentChatWithCondition(at: indexPath)
        var muteTitle = "Unmute"
        var shouldMute = false
        
        if let membersToPush = recent[kMEMBERSTOPUSH] as? String, membersToPush.contains(FIRUser.currentId()) {
            muteTitle = "Mute"
            shouldMute = true
        }
        
        let mute = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            self.muteChat(action: action, at: indexPath, shouldMute: shouldMute)
        }
        let delete = UITableViewRowAction(style: .destructive, title: "Delete", handler: deleteChat)
        mute.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        
        return [delete, mute]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
        }
        return recentChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RECENT_CHAT_CELL, for: indexPath) as? RecentChatCell else { return UITableViewCell() }
        
        let recentChat = getRecentChatWithCondition(at: indexPath)
        
        cell.setupCell(withRecent: recentChat, at: indexPath)
        cell.delegate = self
        
        return cell
    }
    
    fileprivate func muteChat(action: UITableViewRowAction, at indexPath: IndexPath, shouldMute: Bool) {
//        let recent = getRecentChatWithCondition(at: indexPath)
        
        
    }
    
    fileprivate func deleteChat(action: UITableViewRowAction, at indexPath: IndexPath) {
        let recent = getRecentChatWithCondition(at: indexPath)
        
        guard let recentID = recent[kRECENTID] as? String else { return }
       
        if searchController.isActive && searchController.searchBar.text != "" {
            self.filteredChats.remove(at: indexPath.row)
            self.recentChats = recentChats.filter({ (currentRecent) -> Bool in
                return (currentRecent[kWITHUSERUSERID] as? String) != (recent[kWITHUSERUSERID] as? String)
            })
        } else {
            self.recentChats.remove(at: indexPath.row)
        }
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        reference(.Recent).document(recentID).delete()
    }
    
}

extension RecentChatsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count > 0 else {
            tableView.reloadData()
            return
        }
        filterContentForSearch(searchText: searchText)
    }
    
    fileprivate func filterContentForSearch(searchText: String, scope: String = "All") {
        filteredChats = recentChats.filter({ (recent) -> Bool in
            guard let fullname = recent[kWITHUSERFULLNAME] as? String else { return false }
            return fullname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
}
