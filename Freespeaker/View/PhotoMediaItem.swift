//
//  PhotoMediaItem.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/27/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class PhotoMediaItem: JSQPhotoMediaItem {
    override func mediaViewDisplaySize() -> CGSize {
        let defaultSize: CGFloat = 256
        var thimbSize = CGSize(width: defaultSize, height: defaultSize)
        
        if let image = image, image.size.height > 0 && image.size.width > 0 {
            let aspectRatio: CGFloat = image.size.width / image.size.height
            
            if image.size.width > image.size.height {
                thimbSize = CGSize(width: defaultSize, height: defaultSize / aspectRatio)
            } else {
                thimbSize = CGSize(width: defaultSize * aspectRatio, height: defaultSize)
            }
        }
        
        return thimbSize
    }
}
