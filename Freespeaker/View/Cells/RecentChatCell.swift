//
//  RecentChatCell.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/21/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

protocol RecentChatCellDelegate {
    func onAvatarClick(at indexPath: IndexPath)
}

class RecentChatCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    @IBOutlet fileprivate weak var usernameLbl: UILabel!
    @IBOutlet fileprivate weak var lastMessageDateLbl: UILabel!
    @IBOutlet fileprivate weak var messageLbl: UILabel!
    @IBOutlet fileprivate weak var messageCounterContainer: UIView!
    @IBOutlet fileprivate weak var messageCounterLbl: UILabel!
    
    fileprivate var indexPath: IndexPath!
    var delegate: RecentChatCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        messageCounterContainer.layer.cornerRadius = messageCounterContainer.frame.width / 2
        
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onProfilePictureClick)))
    }
    
    func setupCell(withRecent chatData: NSDictionary, at indexPath: IndexPath) {
        self.indexPath = indexPath
        self.usernameLbl.text = chatData[kWITHUSERFULLNAME] as? String
        
        let decryptedText = Encryption.decrypt(chatID: chatData[kCHATROOMID] as? String ?? "", encryptedMessage: chatData[kLASTMESSAGE] as? String ?? "")
        self.messageLbl.text = decryptedText
        
        self.lastMessageDateLbl.text = chatData[kDATE] as? String
        
        if let avatarString = chatData[kAVATAR] as? String {
            imageFromData(pictureData: avatarString) { (image) in
                guard let userImg = image?.circleMasked else { return }
                
                self.profileImageView.image = userImg
            }
        }
        
        if let chatCount = chatData[kCOUNTER] as? Int, chatCount != 0 {
            self.messageCounterLbl.text = "\(chatCount)"
            self.messageCounterContainer.alpha = 1
        } else {
            self.messageCounterContainer.alpha = 0
        }
        
        var date: Date?
        
        if let created = chatData[kDATE] as? String {
            if created.count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created)
            }
        }
        
        self.lastMessageDateLbl.text = timeElapsed(date: date ?? Date())
    }
    
    @objc fileprivate func onProfilePictureClick() {
        delegate?.onAvatarClick(at: indexPath)
    }
}
