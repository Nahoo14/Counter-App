//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import Combine
import CryptoKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func hideKeyboard(){
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

func preloadKeyboard() {
    DispatchQueue.global(qos: .background).async {
        // Simulate interaction
        _ = ""
    }
}

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


class UserViewModel: ObservableObject {

    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    
    private var timer : Timer? = nil
    
    var Data = DataManager()
    
    init() {
        timeEntriesMap = Data.loadMapData()
        print("UserViewModel initialized. Loaded timeEntriesMap:", timeEntriesMap)
        startTimers()
    }
    
    func saveData(){
        Data.timeEntriesMap = timeEntriesMap
        Data.saveMapData()
    }
    
    func addEntry(newEntryTitle: String, startTime: Date) {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle, startTime: startTime)
        timeEntriesMap[newEntryTitle] = newEntry
        startTimer(for: newEntryTitle) // Start the timer for the new entry
        Data.timeEntriesMap = timeEntriesMap
        Data.saveMapData()
    }
    
    // calculateAverage returns the average time per entry.
    func calculateAverage(for title: String) -> TimeInterval{
        let timeEntry = timeEntriesMap[title]
        var time = (timeEntry?.elapsedTime ?? 0)
        let historyCount = (timeEntry?.history?.count ?? 0) + 1
        if let history = timeEntry?.history {
            for entry in history {
                time += entry.elapsedTime
            }
        }
        return time / Double(historyCount)
    }
    
    // longestStreak returns the longest streak.
    func longestStreak(for title: String) -> TimeInterval{
        let timeEntry = timeEntriesMap[title]
        var longest = (timeEntry?.elapsedTime ?? 0)
        if let history = timeEntry?.history {
            for entry in history {
                if entry.elapsedTime > longest{
                    longest = entry.elapsedTime
                }
            }
        }
        return longest
    }
    
    
    func startTimer(for title: String) {
        print("startTimer called for:",title)
        // Updates elapsed time every second.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let currentTime = Date()
            let startTime = self.timeEntriesMap[title]?.startTime
            let isPaused = self.timeEntriesMap[title]?.isPaused ?? false
            if (isPaused){
                self.timeEntriesMap[title]?.elapsedTime = currentTime.timeIntervalSince(currentTime)
                return
            }
            else{
                self.timeEntriesMap[title]?.elapsedTime = currentTime.timeIntervalSince(startTime!)
            }
        }
    }
    
    func startTimers() {
        for key in timeEntriesMap.keys{
            startTimer(for: key)
        }
        saveData()
    }

    func resetTimer(for key: String, reason: String, resetTime: Date) {
        if var entry = timeEntriesMap[key] {
            let newHistory = perItemTimerEntry(startTime: entry.startTime, endTime: resetTime, elapsedTime: resetTime.timeIntervalSince(entry.startTime), resetReason: reason)
            if entry.history?.isEmpty ?? true {
                entry.history = [newHistory]
            } else {
                entry.history?.append(newHistory)
            }
            entry.startTime = resetTime
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        saveData()
    }
    
    func resetAndPauseTimer(for key: String, reason: String, resetTime: Date){
        if var entry = timeEntriesMap[key] {
            let newHistory = perItemTimerEntry(startTime: entry.startTime, endTime: resetTime, elapsedTime: resetTime.timeIntervalSince(entry.startTime), resetReason: reason)
            if entry.history?.isEmpty ?? true {
                entry.history = [newHistory]
            } else {
                entry.history?.append(newHistory)
            }
            entry.isPaused = true
            entry.startTime = resetTime
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        saveData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        saveData()
    }
    
    func timeString(from elapsedTime: TimeInterval) -> String {
        // print("timeEntries map =", timeEntriesMap)
        let days = Int(elapsedTime) / 86400
        let hours = (Int(elapsedTime) % 86400) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    func addRule(rule : String, for title: String){
        timeEntriesMap[title]?.rules = rule
        saveData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules // Return empty string if no rule exists
    }
}
