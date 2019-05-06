//
//  VideoItemMessage.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/28/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//
import JSQMessagesViewController


class VideoMediaItem: JSQVideoMediaItem {
    var image: UIImage?
    var videoImageView: UIImageView?
    var status: Int?
    var filesURL: NSURL?
    
    init(withFile url: NSURL, maskOutgoing: Bool) {
        super.init(maskAsOutgoing: maskOutgoing)
        
        filesURL = url
        videoImageView = nil
    }
    
    override func mediaView() -> UIView! {
        if let status = status {
            if status == 1 {
                return nil
            } else if videoImageView == nil && status == 2 {
                let size = mediaViewDisplaySize()
                let outgoing = appliesMediaViewMaskAsOutgoing
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: .white)
                let iconView = UIImageView(image: icon)
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                iconView.contentMode = .center
                
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.addSubview(iconView)
                
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                self.videoImageView = imageView
            }
        }
        
        return videoImageView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
