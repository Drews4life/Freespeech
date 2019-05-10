//
//  BackgroundsCollectionView.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/8/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import ProgressHUD

class BackgroundsCollectionView: UICollectionViewController {
    
    fileprivate var backgrounds = [UIImage]()
    fileprivate let defaults = UserDefaults.standard
    fileprivate let imageNames = ["bg0","bg1","bg2","bg3","bg4","bg5","bg6","bg7","bg8","bg9","bg10","bg11"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(reset))
        
        getBackgroundImages()
    }
    
    @objc fileprivate func reset() {
        defaults.removeObject(forKey: kBACKGROUNDIMAGE)
        ProgressHUD.showSuccess()
    }
    
    fileprivate func getBackgroundImages() {
        imageNames.forEach { backgrounds.append(UIImage(named: $0) ?? UIImage()) }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defaults.set(imageNames[indexPath.item], forKey: kBACKGROUNDIMAGE)
        ProgressHUD.showSuccess()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgrounds.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BACKGROUND_CELL, for: indexPath) as? BackgroundCell else { return UICollectionViewCell() }
        
        cell.setupCell(backgrounds[indexPath.row])
        
        return cell
    }
}
