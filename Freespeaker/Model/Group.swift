//
//  Group.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/10/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase

class Group {
    let groupDictionary: NSMutableDictionary
    
    init(groupID: String, subject: String, ownerID: String, members: [String], avatar: String) {
        groupDictionary = NSMutableDictionary(objects: [
            groupID, subject, ownerID, members, members, avatar
        ], forKeys: [
            kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying
        ])
    }
    
    static func updateGroup(groupID: String, with values: [String: Any]) {
        reference(.Group).document(groupID).updateData(values)
    }
    
    func saveGroup() {
        let date = dateFormatter().string(from: Date())
        groupDictionary[kDATE] = date
        reference(.Group).document(groupDictionary[kGROUPID] as? String ?? "").setData(groupDictionary as! [String: Any])
    }
    
}
