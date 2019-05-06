//
//  ChatViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/21/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
//import AVFoundation
import AVKit
import Firebase

class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
    
    fileprivate let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    fileprivate let outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1))
    fileprivate let incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1))
    
    fileprivate let profileImgBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: 0, y: 10, width: 25, height: 25)
        
        return btn
    }()
    
    fileprivate let titleLbl: UILabel = {
        let lbl = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        lbl.textAlignment = .left
        lbl.font = .systemFont(ofSize: 14)
        
        
        return lbl
    }()
    
    fileprivate let statusLbl: UILabel = {
        let lbl = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        lbl.textAlignment = .left
        lbl.font = .systemFont(ofSize: 10)
        
        return lbl
    }()
    
    fileprivate let leftBarButton: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        
        return view
    }()
    
    var chatroomID: String!
    var memberIDs: [String]!
    var membersToPush: [String]!
    var titleHeader: String! //{
//        didSet {
//            title = titleHeader
//        }
//    }
    
    var isGroup: Bool?
    fileprivate var group: NSDictionary?
    fileprivate var withUsers = [FIRUser]()
    
    fileprivate var messageListener: ListenerRegistration?
    fileprivate var typingListener: ListenerRegistration?
    fileprivate var updatesListener: ListenerRegistration?
    
    fileprivate let validTypes = [kTEXT, kLOCATION, kVIDEO, kAUDIO, kPICTURE]
    fileprivate var maxMessagesCount = 0
    fileprivate var minMessagesCount = 0
    fileprivate var loadedMessagesCount = 0
    fileprivate var typingCounter = 0
    fileprivate var messages = [JSQMessage]()
    fileprivate var objectMessages = [NSDictionary]()
    fileprivate var loadedMessages = [NSDictionary]()
    fileprivate var allPictureMessages = [String]()
    
    fileprivate var jsqAvatarDictionary: NSMutableDictionary?
    fileprivate var avatarImageDictionary: NSMutableDictionary?
    
    fileprivate var showAvatars = true
    fileprivate var initiallyLoaded = false
    fileprivate var loadOld = false
    fileprivate var firstLoad: Bool?
   
    fileprivate let chatManager = ChatManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = FIRUser.currentId()
        senderDisplayName = FIRUser.currentUser()?.firstname
        inputToolbar.contentView.rightBarButtonItem.setImage(#imageLiteral(resourceName: "mic"), for: .normal)
        inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        
        jsqAvatarDictionary = [:]
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        createTypingListener()
        loadMessages()
        setupNavigationBar()
        loadAllUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        chatManager.clearRecentCounter(chatroomID: chatroomID)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        chatManager.clearRecentCounter(chatroomID: chatroomID)
    }
    
    fileprivate func setupNavigationBar() {
        leftBarButton.addSubview(profileImgBtn)
        leftBarButton.addSubview(titleLbl)
        leftBarButton.addSubview(statusLbl)
//
//        titleLbl.text = "Joshua Rodrigez"
//        statusLbl.text = "onlibe"
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: #imageLiteral(resourceName: "Back"), style: .plain, target: self, action: #selector(onBackBtn)),
            UIBarButtonItem(customView: leftBarButton)
        ]
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "info"), style: .plain, target: self, action: #selector(onInfoBtnClick))
        
        if isGroup == true {
            profileImgBtn.addTarget(self, action: #selector(onShowGroupClick), for: .touchUpInside)
        } else {
            profileImgBtn.addTarget(self, action: #selector(onShowUserClick), for: .touchUpInside)
        }
    }
    
    fileprivate func loadAllUsers() {
        getUsersFromFirestore(withIds: memberIDs) { [weak self] (users) in
            self?.withUsers = users
            self?.getAvatarImages()
            
            if self?.isGroup == false {
                //update user info
                self?.setUIForSingleChat()
            }
        }
    }
    
    fileprivate func createTypingListener() {
        typingListener = reference(.Typing).document(chatroomID).addSnapshotListener({ (snapshot, error) in
            if let err = error {
                print("Could not setup listener for typing: ", err.localizedDescription)
                return
            }
            
            guard let snapshot = snapshot else { return }
            if snapshot.exists {
                if let typingDictionary = snapshot.data() {
                    typingDictionary.forEach({ (data) in
                        if data.key != FIRUser.currentId() {
                            if let typing = data.value as? Bool {
                                self.showTypingIndicator = typing
                            }
                        }
                    })
                }
            } else {
                reference(.Typing).document(self.chatroomID).setData([FIRUser.currentId(): false])
            }
        })
    }
    
    fileprivate func typingCounterStart() {
        typingCounter += 1
        typingCounterSave(typing: true)
        perform(#selector(typingCounterStop), with: nil, afterDelay: 2)
    }
    
    @objc fileprivate func typingCounterStop() {
        typingCounter -= 1
        
        if typingCounter == 0 {
            typingCounterSave(typing: false)
        }
    }
    
    fileprivate func typingCounterSave(typing: Bool) {
        reference(.Typing).document(chatroomID).updateData([FIRUser.currentId(): typing])
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
    }
    
//    shouldSto
    
    @objc fileprivate func onInfoBtnClick() {
        guard let picturesVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: PICTURE_VC) as? PicturesCollectionViewController else { return }
        picturesVC.allImageLinks = allPictureMessages
        
        navigationController?.pushViewController(picturesVC, animated: true)
    }
    
    @objc fileprivate func onShowGroupClick() {
        print("group header click")
    }
    
    @objc fileprivate func onShowUserClick() {
        guard let user = withUsers.first else { return }
        presentUserProfile(for: user)
    }
    
    fileprivate func presentUserProfile(for user: FIRUser) {
        guard let userProfileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: USER_PROFILE_VC) as? ProfileTableViewController else { return }
        userProfileVC.user = user
        
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    fileprivate func setUIForSingleChat() {
        guard let user = withUsers.first else { return }
        imageFromData(pictureData: user.avatar) { (profileImg) in
            guard let userProfileImg = profileImg?.circleMasked else { return }
            self.profileImgBtn.setImage(userProfileImg.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        titleLbl.text = user.fullname
        if user.isOnline {
            statusLbl.text = "Online"
        } else {
            statusLbl.text = "Offline"
        }
        
        profileImgBtn.addTarget(self, action: #selector(onShowUserClick), for: .touchUpInside)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(_delegate: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            camera.PresentMultiCamera(target: self, canEdit: false)
        }

        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let videoLibrary = UIAlertAction(title: "Video Library", style: .default) { (action) in
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            if self.hasAccessToLocation() {
                self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
        }
    
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        takePhotoOrVideo.setValue(#imageLiteral(resourceName: "camera").withRenderingMode(.alwaysTemplate), forKey: "image")
        photoLibrary.setValue(#imageLiteral(resourceName: "picture").withRenderingMode(.alwaysTemplate), forKey: "image")
        videoLibrary.setValue(#imageLiteral(resourceName: "video").withRenderingMode(.alwaysTemplate), forKey: "image")
        shareLocation.setValue(#imageLiteral(resourceName: "location").withRenderingMode(.alwaysTemplate), forKey: "image")
        
        [takePhotoOrVideo, photoLibrary, videoLibrary, shareLocation, cancel].forEach{ optionMenu.addAction($0) }
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentController = optionMenu.popoverPresentationController {
                currentPopoverpresentController.sourceView = inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentController.sourceRect = inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentController.permittedArrowDirections = .up
                
                present(optionMenu, animated: true, completion: nil)
            }
        } else {
            present(optionMenu, animated: true, completion: nil)
        }
    }
    
    fileprivate func getAvatarImages() {
        guard let currentUser = FIRUser.currentUser() else { return }
        if showAvatars {
            collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            avatarImageFrom(user: currentUser)
            
            withUsers.forEach{ avatarImageFrom(user: $0) }
        }
        
        
    }
    
    fileprivate func avatarImageFrom(user: FIRUser) {
        if user.avatar != "" {
            dataImageFromString(pictureString: user.avatar) { (imageData) in
                guard let imageData = imageData else { return }
                if let imageDictionary = self.avatarImageDictionary {
                    imageDictionary.removeObject(forKey: user.objectId)
                    imageDictionary.setObject(imageData, forKey: user.objectId as NSCopying)
                } else {
                    avatarImageDictionary = [user.objectId: imageData]
                }
                
                createJSQAvatars()
            }
        }
    }
    
    fileprivate func createJSQAvatars() {
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: #imageLiteral(resourceName: "avatarPlaceholder"), diameter: 70)
        if let imageDictionary = avatarImageDictionary {
            for memberId in memberIDs {
                if let avatarImgData = imageDictionary[memberId] as? Data {
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImgData), diameter: 70)
                    jsqAvatarDictionary?.setValue(jsqAvatar, forKey: memberId)
                } else {
                    jsqAvatarDictionary?.setValue(defaultAvatar, forKey: memberId)
                }
            }
            
            self.collectionView.reloadData()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let video = info[.mediaURL] as? NSURL
        let picture = info[.originalImage] as? UIImage
        
        picker.dismiss(animated: true, completion: nil)
        
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text != "" {
            sendMessage(text: text, date: Date(), picture: nil, location: nil, video: nil, audio: nil)
            updateSendBtn(isSend: false)
        } else {
            let audioVC = AudioViewController(_delegate: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true, completion: nil)
        sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        var avatar: JSQMessageAvatarImageDataSource
        
        if let userImage = jsqAvatarDictionary?.object(forKey: message.senderId) as? JSQMessageAvatarImageDataSource {
            avatar = userImage
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: #imageLiteral(resourceName: "avatarPlaceholder"), diameter: 70)
        }
        
        return avatar
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell else { return UICollectionViewCell() }
        let messageData = messages[indexPath.row]
        
        if !messageData.isMediaMessage {
//            if messageData.senderId == FIRUser.currentId() {
                cell.textView.textColor = .white
//            } else {
//                cell.textView.textColor = .black
//            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        if messages[indexPath.row].senderId == FIRUser.currentId() {
            return outgoingBubble
        }
        
        return incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        
        let attrStrColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        let status: NSAttributedString
        
        guard let messageStatus = message[kSTATUS] as? String else { return NSAttributedString(string: "") }
        
        switch messageStatus {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            guard let deliveryDate = message[kDATE] as? String else { return NSAttributedString(string: "") }
            let statusText = "Read \(readTimeFrom(dateStr: deliveryDate))"
            status = NSAttributedString(string: statusText, attributes: attrStrColor)
        default:
            status = NSAttributedString(string: "👌")
        }
        
        if indexPath.row == messages.count - 1 {
            return status
        }
        
        return NSAttributedString(string: "")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return indexPath.row % 3 == 0 ? kJSQMessagesCollectionViewCellLabelHeightDefault : 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return indexPath.row == messages.count - 1 && FIRUser.currentId() == messages[indexPath.row].senderId ?
                kJSQMessagesCollectionViewCellLabelHeightDefault
            :
                0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let messageDictionary = objectMessages[indexPath.row]
        let message = messages[indexPath.row]
        
        switch messageDictionary[kTYPE] as! String {
            case kPICTURE:
                guard let mediaItem = message.media as? JSQPhotoMediaItem else { return }
                guard let photos = IDMPhoto.photos(withImages: [mediaItem.image]) else { return }
                guard let browser = IDMPhotoBrowser(photos: photos) else { return }
                present(browser, animated: true, completion: nil)
            case kVIDEO:
                guard let mediaItem = message.media as? VideoMediaItem else { return }
                let player = AVPlayer(url: mediaItem.filesURL! as URL)
                let movPlayer = AVPlayerViewController()
                let session = AVAudioSession.sharedInstance()
            
                try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                movPlayer.player = player
                present(movPlayer, animated: true) {
                    movPlayer.player?.play()
            }
            case kLOCATION:
                guard let mediaItem = message.media as? JSQLocationMediaItem else { return }
                guard let mapVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: MAP_VC) as? MapViewController else { return }
                mapVC.location = mediaItem.location
                
                navigationController?.pushViewController(mapVC, animated: true)
            default:
                break
            }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        let senderId = messages[indexPath.row].senderId
        var selectedUser: FIRUser?
        
        if senderId == FIRUser.currentId() {
            selectedUser = FIRUser.currentUser()
        } else {
            withUsers.forEach { (user) in
                if user.objectId == senderId {
                    selectedUser = user
                }
            }
        }
        
        guard let user = selectedUser else { return }
        presentUserProfile(for: user)
    }
    
    fileprivate func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        guard let currentUser = FIRUser.currentUser() else { return }
        var outgoingMessage: OutgoingMessage?
        let downloader = Downloader()
        let group = DispatchGroup()
        
        if let text = text {
            outgoingMessage = OutgoingMessage(message: text, senderID: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kTEXT)
        } else if let picture = picture {
            group.enter()
            downloader.uploadImage(image: picture, chatRoomId: chatroomID, view: view) { (urlString) in
                if let imageLink = urlString {
                    outgoingMessage = OutgoingMessage(message: "[\(kPICTURE)]", pictureLink: imageLink, senderID: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kPICTURE)
                }
                group.leave()
            }
        } else if let video = video {
            guard let videoData = NSData(contentsOfFile: video.path ?? "") else { return }
            guard let thumbnail = downloader.videoThumbnail(video: video)?.jpegData(compressionQuality: 0.7) else { return }
            
            group.enter()
            downloader.uploadVideo(video: videoData, chatRoomId: chatroomID, view: view) { (videoURL) in
                if let videoLink = videoURL {
                    outgoingMessage = OutgoingMessage(message: "[\(kVIDEO)]", videoLink: videoLink, thumbnail: thumbnail as NSData, senderID: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kVIDEO)
                }
                group.leave()
            }
        } else if let audio = audio {
            group.enter()
            downloader.uploadAudio(autioPath: audio, chatRoomId: chatroomID, view: view) { (audioURL) in
                if let audioLink = audioURL {
                    outgoingMessage = OutgoingMessage(message: "[\(kAUDIO)]", audioLink: audioLink, senderID: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kAUDIO)
                }
                group.leave()
            }
        } else if let locationKey = location {
            guard let coords = appDelegate?.coordinates else { return }
            
            let latitude = NSNumber(value: coords.latitude)
            let longitude = NSNumber(value: coords.longitude)
            
            outgoingMessage = OutgoingMessage(message: "[\(locationKey)]", latitude: latitude, longitude: longitude, senderID: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kLOCATION)
        }
        
        group.notify(queue: .main) {
            guard let outgoingMsg = outgoingMessage else { return }
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.onMessageSent()
            
            outgoingMsg.sendMessage(chatroomID: self.chatroomID, messageDictionary: outgoingMsg.messageDictionary, memberIDs: self.memberIDs, membersToPush: self.membersToPush)
        }
        
    }
    
    fileprivate func onMessageSent() {
//        inputView.v
    }
   
    fileprivate func loadMessages() {
        guard let currentUser = FIRUser.currentUser() else { return }
        
        updatesListener = reference(.Message)
            .document(currentUser.objectId)
            .collection(chatroomID)
            .addSnapshotListener({ (snapshot, error) in
            if let err = error {
                print("Could not setup listener with error: \(err.localizedDescription)")
                return
            }
                guard let snapshot = snapshot else { return }
                if !snapshot.isEmpty {
                    snapshot.documentChanges.forEach({ (diff) in
                        if diff.type == .modified {
                            self.updateMessageStatus(messageDictionary: diff.document.data() as NSDictionary)
                        }
                    })
                }
        })
        
        reference(.Message)
            .document(currentUser.objectId)
            .collection(chatroomID)
            .order(by: kDATE, descending: true)
            .limit(to: 15)
            .getDocuments { (snapshot, error) in
                if let err = error {
                    debugPrint("Could not get latest messages: \(err.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.initiallyLoaded = true
                    self.listenForMessages()
                    return
                }
                
                let unsortedMsgsArray = dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray
                let sortedMsgsArray = unsortedMsgsArray.sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)])
                guard let messagesDictionary = sortedMsgsArray as? [NSDictionary] else {
                    self.listenForMessages()
                    return
                }
            
                
                self.initiallyLoaded = true
                self.loadedMessages = self.removeCorruptedMessages(allMessages: messagesDictionary)
                
                self.insertMessages()
                self.finishReceivingMessage(animated: true)
                self.getPictureMsgs()
                self.getOldMessagesInBG()
                self.listenForMessages()
                //picture messages will go there
        }
    }
    
    fileprivate func updateMessageStatus(messageDictionary: NSDictionary) {
        for index in 0..<objectMessages.count {
            let temp = objectMessages[index]
            if let messageID = messageDictionary[kMESSAGEID] as? String, let tempMessageID = temp[kMESSAGEID] as? String {
                if messageID == tempMessageID {
                    objectMessages[index] = messageDictionary
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    fileprivate func insertMessages() {
        maxMessagesCount = loadedMessages.count - loadedMessagesCount
        minMessagesCount = maxMessagesCount - kNUMBEROFMESSAGES
        
        if minMessagesCount < 0 {
            minMessagesCount = 0
        }
        
        for i in minMessagesCount..<maxMessagesCount {
            let messageDictionary = loadedMessages[i]
            insertInitiallyLoadedMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
    }
    
    fileprivate func insertInitiallyLoadedMessage(messageDictionary: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(_collectionView: collectionView)
        
        if let senderID = messageDictionary[kSENDERID] as? String, senderID != FIRUser.currentId() {
            if let messageID = messageDictionary[kMESSAGEID] as? String {
                OutgoingMessage.updateMessage(withID: messageID, chatID: chatroomID, memberIDs: memberIDs)
            }
        }
        
        if let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatroomID: chatroomID) {
            objectMessages.append(messageDictionary)
            messages.append(message)
        }
        
        return isIncoming(message: messageDictionary)
    }
    
    fileprivate func listenForMessages() {
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0 {
            if let lastLoadedDate = loadedMessages.last?[kDATE] as? String {
                lastMessageDate = lastLoadedDate
            }
        }
        
        messageListener = reference(.Message)
            .document(FIRUser.currentId())
            .collection(chatroomID)
            .whereField(kDATE, isGreaterThan: lastMessageDate)
            .addSnapshotListener({ (snapshot, error) in
                if let err = error {
                    debugPrint("Could not set messages listener: \(err.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                if !snapshot.isEmpty {
                    snapshot.documentChanges.forEach({ (diff) in
                        if diff.type == .added {
                            let messageDictionary = diff.document.data() as NSDictionary
                            if let type = messageDictionary[kTYPE] as? String, self.validTypes.contains(type) {
                                
                                if let link = messageDictionary[kPICTURE] as? String, type == kPICTURE {
                                    self.addNewPicturesMsgLink(link)
                                }
                                
                                if self.insertInitiallyLoadedMessage(messageDictionary: messageDictionary) {
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                
                                self.finishReceivingMessage()
                            }
                        }
                    })
                }
            })
    }
    
    fileprivate func getOldMessagesInBG() {
        if loadedMessages.count > 0 {
            if let firstMsgDate = loadedMessages.first?[kDATE] as? String {
                reference(.Message)
                    .document(FIRUser.currentId())
                    .collection(chatroomID)
                    .whereField(kDATE, isLessThan: firstMsgDate)
                    .getDocuments { (snapshot, error) in
                        if let err = error {
                            debugPrint("Could not get older errors: \(err.localizedDescription)")
                            return
                        }
                    
                        guard let snapshot = snapshot else { return }
                        
                        let unsortedDict = dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray
                        guard let sorted = unsortedDict.sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as? [NSDictionary] else { return }
                        
                        self.loadedMessages = self.removeCorruptedMessages(allMessages: sorted) + self.loadedMessages
                        
                        self.getPictureMsgs()
                        self.maxMessagesCount = self.loadedMessages.count - self.loadedMessagesCount - 1
                        self.minMessagesCount = self.maxMessagesCount - kNUMBEROFMESSAGES
                }
            }
        }
    }
    
    fileprivate func removeCorruptedMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        var tempMessages = allMessages
        
        tempMessages.forEach { (message) in
            guard let msgIndex = tempMessages.firstIndex(of: message) else { return }
            if let type = message[kTYPE] as? String {
                if !validTypes.contains(type) {
                    tempMessages.remove(at: msgIndex)
                }
            } else {
                tempMessages.remove(at: msgIndex)
            }
        }
        
        return tempMessages
    }
    
    fileprivate func loadMoreMessages(maxNum: Int, minNum: Int){
        if loadOld {
            maxMessagesCount = minNum - 1
            minMessagesCount = maxMessagesCount - kNUMBEROFMESSAGES
        }
        
        if minMessagesCount < 0 {
            minMessagesCount = 0
        }
        
        for i in (minMessagesCount...maxMessagesCount).reversed() {
            let messageDict = loadedMessages[i]
            insertNewMessage(messageDict: messageDict)
            loadedMessagesCount += 1
        }
        
        loadOld = true
        self.showLoadEarlierMessagesHeader = loadedMessagesCount != loadedMessages.count
    }
    
    fileprivate func insertNewMessage(messageDict: NSDictionary) {
        let incomingMessage = IncomingMessage(_collectionView: collectionView)
        guard let message = incomingMessage.createMessage(messageDictionary: messageDict, chatroomID: chatroomID) else { return }
        
        objectMessages.insert(messageDict, at: 0)
        messages.insert(message, at: 0)
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.loadMoreMessages(maxNum: maxMessagesCount, minNum: minMessagesCount)
        self.collectionView.reloadData()
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        updateSendBtn(isSend: textView.text != "")
    }
    
    fileprivate func updateSendBtn(isSend: Bool) {
        self.inputToolbar.contentView.rightBarButtonItem.setImage( isSend ? #imageLiteral(resourceName: "send") : #imageLiteral(resourceName: "mic"), for: .normal)
        
        let transition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
        transition.type = .fade
        
        if let layer = inputToolbar.contentView.rightBarButtonItem.imageView?.layer {
            layer.add(transition, forKey: nil)
        }
    }
    
    fileprivate func isIncoming(message: NSDictionary) -> Bool {
        return FIRUser.currentId() != message[kSENDERID] as? String
    }
    
    fileprivate func readTimeFrom(dateStr: String) -> String {
        let date = dateFormatter().date(from: dateStr)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        
        return currentDateFormat.string(from: date ?? Date())
    }
    
    @objc fileprivate func onBackBtn() {
        chatManager.clearRecentCounter(chatroomID: chatroomID)
        
        messageListener?.remove()
        typingListener?.remove()
        updatesListener?.remove()
        
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func addNewPicturesMsgLink(_ link: String) {
        allPictureMessages.append(link)
    }
    fileprivate func getPictureMsgs() {
        allPictureMessages = []
        
        loadedMessages.forEach { (message) in
            if let type = message[kTYPE] as? String, type == kPICTURE {
                if let pictureMessage = message[kPICTURE] as? String {
                    allPictureMessages.append(pictureMessage)
                }
            }
        }
    }
    
    //MARK: Location
    
    func hasAccessToLocation() -> Bool {
        guard let appDelegate = appDelegate else { return false }
        if let _ = appDelegate.locationManager {
            return true
        } else {
            ProgressHUD.showError("Please, give an access to location in Settings menu")
            return false
        }
    }
}
