//
//  EncryptionManager.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 5/7/22.
//

import Foundation
import RNCryptor

class EncryptionManager {
    
    static func encryptMessage(message: String) throws -> String {
        do {
            let messageData = message.data(using: .utf8)!
            let cipherData = RNCryptor.encrypt(data: messageData, withPassword: "9879e7dfe2")
            return cipherData.base64EncodedString()
        }
    }
    
    static func decryptMessage(encryptedMessage: String) throws -> String {
        do {
            let encryptedData = Data.init(base64Encoded: encryptedMessage)!
            let decryptedData = try RNCryptor.decrypt(data: encryptedData, withPassword: "9879e7dfe2")
            let decryptedString = String(data: decryptedData, encoding: .utf8)!
            return decryptedString
        }
    }
    
}
