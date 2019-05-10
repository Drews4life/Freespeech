//
//  SettingsTableViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/18/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class SettingsTableViewController: UITableViewController {
    static func share(in vc: UIViewController) {
        let shareText = "Hey, check out this application"
        let objectsToShare: [Any] = [shareText]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = vc.view
        activityViewController.setValue("Chat there!", forKey: "subject")
        vc.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var profileStatusSwitch: UISwitch!
    @IBOutlet weak var deleteBtn: UIButton!
    
    fileprivate let userDefaults = UserDefaults.standard
    
    fileprivate var profileImageSwitchStatus = false
    fileprivate var firstLoad: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        
        setupNavBar()
        setupLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupLayout()
    }
    
    fileprivate func setupLayout() {
        guard let currentUser = FIRUser.currentUser() else { return }
        fullnameLbl.text = currentUser.fullname
        loadUserDefaults()
        
        if currentUser.avatar.count > 0 {
            imageFromData(pictureData: currentUser.avatar) { [weak self] (image) in
                guard let image = image?.circleMasked else { return }
                self?.profileImageView.image = image
            }
        }
    }
    
    fileprivate func saveToUserDefaults() {
        userDefaults.set(profileImageSwitchStatus, forKey: kSHOWAVATAR)
    }
    
    fileprivate func loadUserDefaults() {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if let first = firstLoad, !first {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(profileImageSwitchStatus, forKey: kSHOWAVATAR)
        }
        
        profileImageSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        profileStatusSwitch.isOn = profileImageSwitchStatus
    }
    
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 10
        default:
            return 30
        }
    }
    
    @IBAction func onLogOutClick(_ sender: Any) {
        FIRUser.logOutCurrentUser { [weak self] (success) in
            if success {
                let loginScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: WELCOME_VC)
                self?.present(loginScreen, animated: true, completion: nil)
            }
        }
    }
    @IBAction func showProfileImageSwitchChanged(_ sender: UISwitch) {
        profileImageSwitchStatus = sender.isOn
        saveToUserDefaults()
    }
    
    @IBAction func onCleanCacheClick(_ sender: Any) {
        do {
            let documentsPath = Downloader().getDocumentsURL().path
            let files = try FileManager.default.contentsOfDirectory(atPath: documentsPath)
            
            for file in files {
                try FileManager.default.removeItem(atPath: "\(documentsPath)/\(file)")
            }
            ProgressHUD.showSuccess("Cleaned")
        } catch {
            ProgressHUD.showError("Could not clear cache")
        }
    }
    
    @IBAction func onShareClick(_ sender: Any) {
        SettingsTableViewController.share(in: self)
    }
    
    @IBAction func onDeleteUserClick(_ sender: Any) {
        let warningAlert = UIAlertController(title: "Are you sure?", message: "This action will erase your account", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                
        }
        let delete = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.deleteUser()
        }
        
        warningAlert.addAction(cancel)
        warningAlert.addAction(delete)
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentController = warningAlert.popoverPresentationController {
                currentPopoverpresentController.sourceView = deleteBtn
                currentPopoverpresentController.sourceRect = deleteBtn.bounds
                
                currentPopoverpresentController.permittedArrowDirections = .up
                
                present(warningAlert, animated: true, completion: nil)
            }
        } else {
            present(warningAlert, animated: true, completion: nil)
        }
    }
    
    fileprivate func deleteUser() {
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        
        ProgressHUD.show()
        
        reference(.User).document(FIRUser.currentId()).delete { (error) in
            if let err = error {
                print("Unable to delete user from db: \(err.localizedDescription)")
                ProgressHUD.dismiss()
                return
            }
            
            FIRUser.deleteUser(completion: { [weak self] (error) in
                ProgressHUD.dismiss()
                if let err = error {
                    print("Could not delete user object: \(err.localizedDescription)")
                    return
                }
                
                let loginScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: WELCOME_VC)
                self?.present(loginScreen, animated: true, completion: nil)
            })
        }
    }
    
}
