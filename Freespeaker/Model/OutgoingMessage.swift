//
//  OutgoingMessage.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/22/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation

class OutgoingMessage {
    let messageDictionary: NSMutableDictionary
    
    //text message init
    init(message: String, senderID: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [
            message, senderID, senderName, dateFormatter().string(from: date), status, type
        ], forKeys: [
            kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying
        ])
    }
   
    //picture message init
    init(message: String, pictureLink: String, senderID: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [
            message, pictureLink, senderID, senderName, dateFormatter().string(from: date), status, type
            ], forKeys: [
                kMESSAGE as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying
            ])
    }
    
    //video message init
    init(message: String, videoLink: String, thumbnail: NSData, senderID: String, senderName: String, date: Date, status: String, type: String) {
        
        let picThumbnail = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        messageDictionary = NSMutableDictionary(objects: [
            message, videoLink, picThumbnail, senderID, senderName, dateFormatter().string(from: date), status, type
            ], forKeys: [
                kMESSAGE as NSCopying, kVIDEO as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying
            ])
    }
    
    //audio message init
    init(message: String, audioLink: String, senderID: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [
            message, audioLink, senderID, senderName, dateFormatter().string(from: date), status, type
            ], forKeys: [
                kMESSAGE as NSCopying, kAUDIO as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying
            ])
    }
    
    //location message init
    init(message: String, latitude: NSNumber, longitude: NSNumber, senderID: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [
            message, latitude, longitude, senderID, senderName, dateFormatter().string(from: date), status, type
            ], forKeys: [
                kMESSAGE as NSCopying, kLATITUDE as NSCopying, kLONGITUDE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying
            ])
    }
    
    func sendMessage(chatroomID: String, messageDictionary: NSMutableDictionary, memberIDs: [String], membersToPush: [String]) {
        let messageID = UUID().uuidString
        
        messageDictionary[kMESSAGEID] = messageID
        guard let messageDictionaryFIR = messageDictionary as? [String: Any] else { return }
        
        memberIDs.forEach { (memberID) in
            reference(.Message)
                .document(memberID)
                .collection(chatroomID)
                .document(messageID)
                .setData(messageDictionaryFIR, completion: { (error) in
                    if let err = error {
                        debugPrint("Error occured while sending message: \(err.localizedDescription)")
                        return
                    }
                })
        }
        ChatManager().updateRecents(chatroomID: chatroomID, lastMessage: messageDictionary[kMESSAGE] as? String ?? "")
        //send push
    }
    
    static func deleteMessage(withID id: String, chatID: String) {
        
    }
    
    static func updateMessage(withID id: String, chatID: String, memberIDs: [String]) {
        let readDate = dateFormatter().string(from: Date())
        let values = [kSTATUS: kREAD, kREADDATE: readDate] as [String: Any]
        
        memberIDs.forEach { (memberID) in
            reference(.Message).document(memberID).collection(chatID).document(id).getDocument(completion: { (snapshot, _) in
                guard let snapshot = snapshot else { return }
                if snapshot.exists {
                    reference(.Message).document(memberID).collection(chatID).document(id).updateData(values)
                }
            })
        }
    }
}
