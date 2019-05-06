//
//  FirebaseService.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/13/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import Firebase

class DataService {
    
    let shared = DataService()
    
    func sendSingleMessage(roomID: String, content: String, completion: @escaping (_ success: Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newMessageField: [String: Any] = [
            "from": uid,
            "content": content,
            "contentType": "TEXT",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        Firestore
            .firestore()
            .collection("rooms")
            .document(roomID)
            .setData(newMessageField, merge: true) { (error) in
                if let err = error {
                    
                }
        }
    }
}
