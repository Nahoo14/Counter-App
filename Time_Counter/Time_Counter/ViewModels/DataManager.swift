//
//  DataManager.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//
import SwiftUI
import Combine

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
