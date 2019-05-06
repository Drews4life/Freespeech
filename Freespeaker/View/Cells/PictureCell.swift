//
//  PictureCell.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/5/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

class PictureCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setupCell(with image: UIImage) {
        imageView.image = image
    }
}
