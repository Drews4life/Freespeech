//
//  Recent.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/19/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import Firebase

class ChatManager {
    
    @discardableResult
    func startPrivateChat(user1: FIRUser, user2: FIRUser) -> String {
        let userFirstID = user1.objectId
        let userSecondID = user2.objectId
        
        var roomID = ""
        
        let comparedValue = userFirstID.compare(userSecondID).rawValue
        
        if comparedValue < 0 {
            roomID = userFirstID + userSecondID
        } else {
            roomID = userSecondID + userFirstID
        }
        
        let members = [userFirstID, userSecondID]
        
        createRecent(members: members, chatroomID: roomID, username: "", type: kPRIVATE, users: [user1, user2], avatarGroup: nil)
        
        return roomID
    }
    
    func restartRecentChat(recent: NSDictionary) {
        guard let members = recent[kMEMBERSTOPUSH] as? [String] else { return }
        guard let chatroomID = recent[kCHATROOMID] as? String else { return }
        guard let currentUser = FIRUser.currentUser() else { return }
        
        let withUsername = (recent[kWITHUSERUSERNAME] as? String ?? recent[kWITHUSERFULLNAME] as? String) ?? ""
        
        if let recentType = recent[kTYPE] as? String, recentType == kPRIVATE {
            createRecent(members: members, chatroomID: chatroomID, username: currentUser.fullname, type: kPRIVATE, users: [currentUser], avatarGroup: nil)
        } else {
            createRecent(members: members, chatroomID: chatroomID, username: withUsername, type: kGROUP, users: nil, avatarGroup: recent[kAVATAR] as? String)
        }
    }
    
    private func createRecent(members: [String], chatroomID: String, username: String, type: String, users: [FIRUser]?, avatarGroup: String?) {
        
        var tempMembers = members
        
        reference(.Recent)
            .whereField(kCHATROOMID, isEqualTo: chatroomID)
            .getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                
                if !snapshot.isEmpty {
                    snapshot.documents.forEach({ (recentSnapshot) in
                        let currentRecent = recentSnapshot.data()
                        
                        if let currentUserID = currentRecent[kUSERID] as? String {
                            if tempMembers.contains(currentUserID) {
                                tempMembers = tempMembers.filter{ $0 != currentUserID }
                            }
                        }
                    })
                    
                
                }
                
                tempMembers.forEach({ (userID) in
                    self.createRecentItems(userID: userID, chatroomID: chatroomID, members: members, username: username, type: type, users: users, avatarGroup: avatarGroup)
                })
        }
    }
    
    func startGroupChat(group: Group) {
        let chatroomID = group.groupDictionary[kGROUPID] as? String ?? ""
        let members = group.groupDictionary[kMEMBERS] as? [String] ?? []
        createRecent(members: members, chatroomID: chatroomID, username: group.groupDictionary[kNAME] as? String ?? "", type: kGROUP, users: nil, avatarGroup: group.groupDictionary[kAVATAR] as? String)
    }
    
    func createRecentForNewMembers(groupID: String, groupName: String, membersToPush: [String], avatar: String) {
        createRecent(members: membersToPush, chatroomID: groupID, username: groupName, type: kGROUP, users: nil, avatarGroup: avatar)
    }
    
    private func createRecentItems(userID: String, chatroomID: String, members: [String], username: String, type: String, users: [FIRUser]?, avatarGroup: String?) {
        let ref = reference(.Recent).document()
        let recentID = ref.documentID
        
        let date = dateFormatter().string(from: Date())
        var recent: [String: Any] = [:]
        
        if type == kPRIVATE {
            var withUser: FIRUser?
            
            if let users = users, users.count > 0 {
                if userID == FIRUser.currentId() {
                    withUser = users.last
                } else {
                    withUser = users.first
                }
            }
            
            if let withUser = withUser {
                recent = [
                    kRECENTID: recentID,
                    kUSERID: userID,
                    kCHATROOMID: chatroomID,
                    kMEMBERS: members,
                    kMEMBERSTOPUSH: members,
                    kWITHUSERFULLNAME: withUser.fullname,
                    kWITHUSERUSERID: withUser.objectId,
                    kLASTMESSAGE: "",
                    kCOUNTER: 0,
                    kDATE: date,
                    kTYPE: type,
                    kAVATAR: withUser.avatar
                ]
                
            }
            
        } else {
            //group
            if let avatarGroup = avatarGroup {
                recent = [
                    kRECENTID: recentID,
                    kUSERID: userID,
                    kCHATROOMID: chatroomID,
                    kMEMBERS: members,
                    kMEMBERSTOPUSH: members,
                    kWITHUSERFULLNAME: username,
                    kLASTMESSAGE: "",
                    kCOUNTER: 0,
                    kDATE: date,
                    kTYPE: type,
                    kAVATAR: avatarGroup
                ]
            }
        }
        
        ref.setData(recent) { (error) in
            if let err = error {
                debugPrint("Could not create chat: \(err.localizedDescription)")
                return
            }
            
        }
    }
    
    func updateRecents(chatroomID: String, lastMessage: String) {
        getRecentChatrooms(chatroomID: chatroomID) { (documents) in
            guard let documents = documents else { return }
            
            documents.forEach({ (recent) in
                let currentRecent = recent.data() as NSDictionary
                if let userId = currentRecent[kUSERID] as? String, userId == FIRUser.currentId() {
                    self.updateRecentsItem(for: currentRecent, lastMessage: lastMessage)
                }
            })
        }
    }
    
    private func updateRecentsItem(for recent: NSDictionary, lastMessage: String) {
        guard let recentID = recent[kRECENTID] as? String else { return }
        guard var counter = recent[kCOUNTER] as? Int else { return }
        
        let date = dateFormatter().string(from: Date())
        
        if let userId = recent[kUSERID] as? String, userId != FIRUser.currentId() {
            counter += 1
        }
        
        let values: [String: Any] = [kLASTMESSAGE: lastMessage, kCOUNTER: counter, kDATE: date]
        reference(.Recent).document(recentID).updateData(values)
    }
    
    func clearRecentCounter(chatroomID: String) {
        getRecentChatrooms(chatroomID: chatroomID) { (documents) in
            guard let documents = documents else { return }
            
            documents.forEach({ (recent) in
                let currentRecent = recent.data() as NSDictionary
                if let userId = currentRecent[kUSERID] as? String, userId == FIRUser.currentId() {
                    self.clearRecentCounterItem(for: currentRecent)
                }
            })
        }
    }
    
    private func clearRecentCounterItem(for recent: NSDictionary) {
        guard let recentID = recent[kRECENTID] as? String else { return }
        reference(.Recent).document(recentID).updateData([kCOUNTER: 0])
    }
    
    func updateExistingRecent(with values: [String: Any], for chatroomID: String, withMembers members: [String]) {
        getRecentChatrooms(chatroomID: chatroomID) { (documents) in
            guard let documents = documents else { return }
            
            documents.forEach({ (recent) in
                let currentRecent = recent.data() as NSDictionary
                self.updateRecent(recentID: currentRecent[kRECENTID] as? String ?? "", with: values)
            })
        }
    }
    
    private func updateRecent(recentID: String, with values: [String: Any]) {
        reference(.Recent).document(recentID).updateData(values)
    }
    
    func block(user: FIRUser) {
        let userId1 = FIRUser.currentId()
        let userId2 = user.objectId
        
        var chatroomID = ""
        
        let value = userId1.compare(userId2).rawValue
        
        if value < 0 {
            chatroomID = userId1 + userId2
        } else {
            chatroomID = userId2 + userId1
        }
        
        getRecents(for: chatroomID)
    }
    
    func getRecents(for chatroomID: String) {
        getRecentChatrooms(chatroomID: chatroomID) { (documents) in
            guard let documents = documents else { return }
            
            documents.forEach({ (recent) in
                let currentRecent = recent.data() as NSDictionary
                self.deleteRecentChat(recent: currentRecent)
            })
        }
    }
    
    func deleteRecentChat(recent: NSDictionary) {
        guard let recentID = recent[kRECENTID] as? String else { return }
        reference(.Recent).document(recentID).delete()
    }
    
    private func getRecentChatrooms(chatroomID: String, completion: @escaping ([QueryDocumentSnapshot]?) -> Void) {
        reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatroomID).getDocuments { (snapshot, error) in
            if let err = error {
                print("Could not get chats by id: \(err.localizedDescription)")
                return completion(nil)
            }
            
            guard let snapshot = snapshot else { return completion(nil) }
            if !snapshot.isEmpty {
                completion(snapshot.documents)
            } else {
                completion(nil)
            }
        }
    }
}
