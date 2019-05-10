//
//  BackgroundCell.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/8/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit

class BackgroundCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func setupCell(_ image: UIImage) {
        imageView.image = image
    }
}
