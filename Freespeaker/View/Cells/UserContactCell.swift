//
//  UserContactCell.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/18/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

protocol UserContactCellDelegate {
    func didClickProfileImage(at indexPath: IndexPath)
}

class UserContactCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    @IBOutlet fileprivate weak var contactNameLbl: UILabel!
    
    fileprivate var indexPath: IndexPath!
    
    var delegate: UserContactCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectProfileImg)))
    }
    
    @objc fileprivate func didSelectProfileImg() {
        delegate?.didClickProfileImage(at: indexPath)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupCell(withUser user: FIRUser, forPath indexPath: IndexPath) {
        contactNameLbl.text = user.fullname
        
        if user.avatar.count > 0 {
            imageFromData(pictureData: user.avatar) { (userImage) in
                if let img = userImage {
                    self.profileImageView.image = img.circleMasked
                }
            }
        }
        
        self.indexPath = indexPath
    }
}
