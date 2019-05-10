//
//  GroupMemberCell.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/10/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

protocol GroupMemberCellDelegate {
    func didClickCancel(at indexPath: IndexPath)
}

class GroupMemberCell: UICollectionViewCell {
    
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    @IBOutlet fileprivate weak var usernameLbl: UILabel!
    
    var indexPath: IndexPath!
    var delegate: GroupMemberCellDelegate?
    
    
    func setupCell(user: FIRUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.usernameLbl.text = user.fullname
        
        if user.avatar.count > 0 {
            imageFromData(pictureData: user.avatar) { (image) in
                guard let image = image?.circleMasked else { return }
                self.profileImageView.image = image
            }
        }
    }
    
    @IBAction func onCancelUserClick(_ sender: Any) {
        delegate?.didClickCancel(at: indexPath)
    }
    
}
