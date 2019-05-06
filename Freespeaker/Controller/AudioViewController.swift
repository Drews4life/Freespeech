//
//  AudioViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/16/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//


import Foundation
import IQAudioRecorderController

class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(_delegate: IQAudioRecorderViewControllerDelegate) {
        delegate = _delegate
    }
    
    func presentAudioRecorder(target: UIViewController) {
        
        let controller = IQAudioRecorderViewController()
        
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
    
}
