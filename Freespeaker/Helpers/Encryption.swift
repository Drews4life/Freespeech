//
//  Encryption.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 5/12/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import Foundation
import RNCryptor

class Encryption {
    static func encrypt(chatID: String, message: String) -> String {
        guard let data = message.data(using: String.Encoding.utf8) else { return "" }
        let encryptedData = RNCryptor.encrypt(data: data, withPassword: chatID)
        
        return encryptedData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
    
    static func decrypt(chatID: String, encryptedMessage: String) -> String {
        let decryptor = RNCryptor.Decryptor(password: chatID)
        let encryptedData = NSData(base64Encoded: encryptedMessage, options: NSData.Base64DecodingOptions(rawValue: 0))
        
        var message: NSString = ""
        
        if let data = encryptedData as Data? {
            do {
                let descryptedData = try decryptor.decrypt(data: data)
                message = NSString(data: descryptedData, encoding: String.Encoding.utf8.rawValue) ?? ""
            } catch {
                print("Could not decrypt message with error: \(error.localizedDescription)")
            }
        }
        
        return message as String
    }
}
