//
//  Download.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/16/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

class Downloader {

    let storage = Storage.storage()

    func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
        
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        progressHUD.mode = .determinateHorizontalBar
        
        let dateString = dateFormatter().string(from: Date())
        let photoFileName = "PictureMessages/" + FIRUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
        let imageData = image.jpegData(compressionQuality: 0.7)
        var task: StorageUploadTask!
        
        task = storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
            
            task.removeAllObservers()
            progressHUD.hide(animated: true)
            
            if let err = error  {
                print("error uploading image \(err.localizedDescription)")
                return
            }
            
            
            storageRef.downloadURL(completion: { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            })
            
        })
        
        
        task.observe(StorageTaskStatus.progress) { (snapshot) in
            
            progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        }
        
    }


    func downloadImage(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
        
        let imageURL = NSURL(string: imageUrl)
        
        let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
        
        if fileExistsAtPath(path: imageFileName) {
            
            //exist
            if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
                completion(contentsOfFile)
            } else {
                print("could not generate image")
                completion(nil)
            }
            
        } else {
            //doesnt exist
            
            let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
            
            downloadQueue.async {
                
                let data = NSData(contentsOf: imageURL! as URL)
                
                if let data = data {
                    
                    var docURL = self.getDocumentsURL()
                    
                    docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                    
                    data.write(to: docURL, atomically: true)
                    
                    let imageToReturn = UIImage(data: data as Data)
                    
                    DispatchQueue.main.async {
                        completion(imageToReturn!)
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        print("no image in database")
                        completion(nil)
                    }
                }
            }
        }
    }


    //video
    func uploadVideo(video: NSData, chatRoomId: String, view: UIView, completion: @escaping(_ videoLink: String?) -> Void) {
        
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        progressHUD.mode = .determinateHorizontalBar
        let dateString = dateFormatter().string(from: Date())
        let videoFileName = "VideoMessages/" + FIRUser.currentId() + "/" + chatRoomId + "/" + dateString + ".mov"
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
        var task : StorageUploadTask!
        
        task = storageRef.putData(video as Data, metadata: nil, completion: { (metadata, error) in
            
            task.removeAllObservers()
            progressHUD.hide(animated: true)
            
            if let err = error {
                print("error couldnty upload video \(err.localizedDescription)")
                return
            }
            
            storageRef.downloadURL(completion: { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            })
        })
        
        task.observe(StorageTaskStatus.progress) { (snapshot) in
            
            progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        }
    }

    func downloadVideo(videoUrl: String, completion: @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
        
        let videoURL = NSURL(string: videoUrl)
        let videoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
        
        if fileExistsAtPath(path: videoFileName) {
            
            completion(true, videoFileName)
        } else {
            let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
            
            downloadQueue.async {
                
                let data = NSData(contentsOf: videoURL! as URL)
                
                if let data = data {
                    
                    var docURL = self.getDocumentsURL()
                    
                    docURL = docURL.appendingPathComponent(videoFileName, isDirectory: false)
                    
                    data.write(to: docURL, atomically: true)
                
                    DispatchQueue.main.async {
                        completion(true, videoFileName)
                    }
                    
                } else {
                    //need to call completion and return nil if no file is available
                    DispatchQueue.main.async {
                        debugPrint("\nMISSING IMPLEMENTATION FOR NOT FOUND VIDEO\n")
//                        completion(false, nil)
                    }
                }
            }
        }
    }


    //Audio messages

    func uploadAudio(autioPath: String, chatRoomId: String, view: UIView, completion: @escaping(_ audioLink: String?) -> Void) {
        
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        progressHUD.mode = .determinateHorizontalBar
        
        let dateString = dateFormatter().string(from: Date())
        let audioFileName = "AudioMessages/" + FIRUser.currentId() + "/" + chatRoomId + "/" + dateString + ".m4a"
        let audio = NSData(contentsOfFile: autioPath)
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
        var task : StorageUploadTask!
        
        task = storageRef.putData(audio! as Data, metadata: nil, completion: { (metadata, error) in
            
            task.removeAllObservers()
            progressHUD.hide(animated: true)
            
            if let err = error {
                print("error couldnty upload audio \(err.localizedDescription)")
                return
            }
            
            storageRef.downloadURL(completion: { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            })
        })
        
        task.observe(StorageTaskStatus.progress) { (snapshot) in
            
            progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        }
    }


    func downloadAudio(audioUrl: String, completion: @escaping(_ audioFileName: String) -> Void) {
        
        let audioURL = NSURL(string: audioUrl)
        
        let audioFileName = (audioUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
        
        
        if fileExistsAtPath(path: audioFileName) {
            completion(audioFileName)
            
        } else {
            let downloadQueue = DispatchQueue(label: "audioDownloadQueue")
            downloadQueue.async {
                
                let data = NSData(contentsOf: audioURL! as URL)
                
                if let data = data {
                    
                    var docURL = self.getDocumentsURL()
                    
                    docURL = docURL.appendingPathComponent(audioFileName, isDirectory: false)
                    
                    data.write(to: docURL, atomically: true)
        
                    DispatchQueue.main.async {
                        completion(audioFileName)
                    }
                    
                } else {
                    //need to call completion and return nil if no file is available
                    
                    DispatchQueue.main.async {
                        print("no audio in database")
                    }
                }
            }
        }
    }


    //Helpers

    func videoThumbnail(video: NSURL) -> UIImage? {
        
        let asset = AVURLAsset(url: video as URL, options: nil)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 1000)
        var actualTime = CMTime.zero
        
        var image: CGImage?
        
        do {
            image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard let thumnImage = image else { return nil }
        let thumbnail = UIImage(cgImage: thumnImage)
        
        return thumbnail
    }



    func fileInDocumentsDirectory(fileName: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(fileName)
        return fileURL.path
    }


    fileprivate func getDocumentsURL() -> URL {
        
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        
        return documentURL!
    }

    fileprivate func fileExistsAtPath(path: String) -> Bool {
        
        var doesExist = false
        
        let filePath = fileInDocumentsDirectory(fileName: path)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            doesExist = true
        }else {
            doesExist = false
        }
        
        return doesExist
    }

}
