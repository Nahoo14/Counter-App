//
//  Encryption.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import SwiftUI
import Combine
import CryptoKit

struct EncryptionManager {
    private static let keyStoreKey = "encryptionKey"
    
    static func getEncryptionKey() -> SymmetricKey {
        if let keyData = UserDefaults.standard.data(forKey: keyStoreKey) {
            return SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            storeEncryptionKey(newKey)
            return newKey
        }
    }
    
    private static func storeEncryptionKey(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        UserDefaults.standard.set(keyData, forKey: keyStoreKey)
    }
    
    static func encryptData(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: getEncryptionKey())
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    static func decryptData(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: getEncryptionKey())
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
}

class DataManager {
    private let storageKey = "timeMap"
    var timeEntriesMap: [String: TimerEntry] = [:]
    
    func saveMapData() {
        do {
            let data = try JSONEncoder().encode(timeEntriesMap)
            if let encryptedData = EncryptionManager.encryptData(data) {
                UserDefaults.standard.set(encryptedData, forKey: storageKey)
                UserDefaults.standard.synchronize()
            }
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    func loadMapData() -> [String: TimerEntry] {
        do {
            if let savedData = UserDefaults.standard.data(forKey: storageKey),
               let decryptedData = EncryptionManager.decryptData(savedData) {
                let loadedMap = try JSONDecoder().decode([String: TimerEntry].self, from: decryptedData)
                print("Loaded timeEntriesMap:", loadedMap)
                return loadedMap
            }
        } catch {
            print("Failed to load data: \(error)")
        }
        print("Found nothing stored.")
        return [:] // Return empty map if loading fails
    }

}
