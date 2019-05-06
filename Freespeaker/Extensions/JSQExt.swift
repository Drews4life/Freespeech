//
//  JSQExt.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/21/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import JSQMessagesViewController

extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}
