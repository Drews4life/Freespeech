//
//  PicturesCollectionViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/5/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class PicturesCollectionViewController: UICollectionViewController {
    
    var allImages = [UIImage]()
    var allImageLinks = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "All Pictures"
        
        if allImageLinks.count > 0 {
            downloadImages()
        }
    }
    
    fileprivate func downloadImages() {
        let downloader = Downloader()
        allImageLinks.forEach { downloader.downloadImage(imageUrl: $0, completion: { [unowned self] (image) in
            if let image = image {
                self.allImages.append(image)
            }
        })}
        
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photos = IDMPhoto.photos(withImages: allImages)
        guard let browser = IDMPhotoBrowser(photos: photos) else { return }
        browser.displayDoneButton = false
        browser.setInitialPageIndex(UInt(indexPath.item))
        
        present(browser, animated: true, completion: nil)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allImages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PICTURE_CELL, for: indexPath) as? PictureCell else { return UICollectionViewCell() }
        
        cell.setupCell(with: allImages[indexPath.row])
        
        return cell
    }
    
}
