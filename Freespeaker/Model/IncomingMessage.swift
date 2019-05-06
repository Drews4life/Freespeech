//
//  IncomingMessage.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/22/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    let collectionView: JSQMessagesCollectionView
    let downloader = Downloader()
    
    init(_collectionView: JSQMessagesCollectionView) {
        collectionView = _collectionView
    }
    
    func createMessage(messageDictionary: NSDictionary, chatroomID: String) -> JSQMessage? {
        var message: JSQMessage?
        
        guard let type = messageDictionary[kTYPE] as? String else { return nil }
        
        switch type {
            case kTEXT:
                message = createTextMsg(messageDictionary: messageDictionary, chatroomID: chatroomID)
            case kPICTURE:
                message = createPictureMsg(messageDictionary: messageDictionary)
            case kVIDEO:
                message = createVideoMsg(messageDictionary: messageDictionary)
            case kAUDIO:
                message = createAudioMsg(messageDictionary: messageDictionary)
            case kLOCATION:
                message = createLocationMsg(messageDictionary: messageDictionary)
            default:
                print("\nUndefined message type\n")
        }
        
        return message
    }
    
    func createTextMsg(messageDictionary: NSDictionary, chatroomID: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userID = messageDictionary[kSENDERID] as? String
        let text = messageDictionary[kMESSAGE] as? String
        let date = getMessageDate(dateString: messageDictionary[kDATE] as? String)
        
        return JSQMessage(senderId: userID, senderDisplayName: name, date: date, text: text)
    }
    
    func createPictureMsg(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userID = messageDictionary[kSENDERID] as? String
        let date = getMessageDate(dateString: messageDictionary[kDATE] as? String)
        
        let imageURLString = messageDictionary[kPICTURE] as? String ?? ""
        let mediaItem = JSQPhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatus(forUser: userID ?? "")
        
        downloader.downloadImage(imageUrl: imageURLString) { (messageImage) in
            if let msgImg = messageImage {
                mediaItem?.image = msgImg
                self.collectionView.reloadData()
            }
        }
        
        return JSQMessage(senderId: userID, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func createVideoMsg(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userID = messageDictionary[kSENDERID] as? String
        let date = getMessageDate(dateString: messageDictionary[kDATE] as? String)
        
        let urlString = messageDictionary[kVIDEO] as? String ?? ""
        let videoURL = NSURL(fileURLWithPath: urlString)
        let thumbnail = messageDictionary[kPICTURE] as? String ?? ""
        let mediaItem = VideoMediaItem(withFile: videoURL, maskOutgoing: returnOutgoingStatus(forUser: userID ?? ""))
        
        downloader.downloadVideo(videoUrl: urlString) { (isReadyToPlay, videoName) in
            let url = NSURL(fileURLWithPath: self.downloader.fileInDocumentsDirectory(fileName: videoName))
            mediaItem.status = kSUCCESS
            mediaItem.filesURL = url
            
            imageFromData(pictureData: thumbnail, withBlock: { (thumbnailImg) in
                guard let thumbnailUIImage = thumbnailImg else { return }
                mediaItem.image = thumbnailUIImage
                self.collectionView.reloadData()
            })
            
            self.collectionView.reloadData()
        }
        return JSQMessage(senderId: userID, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func createAudioMsg(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userID = messageDictionary[kSENDERID] as? String
//        let date = getMessageDate(dateString: messageDictionary[kDATE] as? String)
        
        let audioItem = JSQAudioMediaItem(data: nil)
        audioItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatus(forUser: userID ?? "")
        
        let audioURLString = messageDictionary[kAUDIO] as? String ?? ""
        
        downloader.downloadAudio(audioUrl: audioURLString) { (audioPath) in
            let audioUrl = NSURL(fileURLWithPath: self.downloader.fileInDocumentsDirectory(fileName: audioPath))
            let audioData = try? Data(contentsOf: audioUrl as URL)
            audioItem.audioData = audioData
            self.collectionView.reloadData()
        }
        
        return JSQMessage(senderId: userID, displayName: name, media: audioItem)
    }
    
    func createLocationMsg(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userID = messageDictionary[kSENDERID] as? String
//        let text = messageDictionary[kMESSAGE] as? String
        let date = getMessageDate(dateString: messageDictionary[kDATE] as? String)
        
        let latitude = messageDictionary[kLATITUDE] as? Double ?? 0.0
        let longitude = messageDictionary[kLONGITUDE] as? Double ?? 0.0
        
        let mediaItem = JSQLocationMediaItem(location: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatus(forUser: userID ?? "")
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        mediaItem?.setLocation(location, withCompletionHandler: {
            self.collectionView.reloadData()
        })
        
        
        
        return JSQMessage(senderId: userID, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    fileprivate func returnOutgoingStatus(forUser id: String) -> Bool {
        return id == FIRUser.currentId()
    }
    
    fileprivate func getMessageDate(dateString: String?) -> Date {
        guard let created = dateString else { return Date() }
        return dateFormatter().date(from: created) ?? Date()
    }
}
