//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import Combine

class UserViewModel: ObservableObject {

    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    
    var newEntryTitle: String = ""
    private var timer : Timer? = nil
    
    init() {
        loadMapData()
        startTimers()
    }
        
    func saveMapData() {
        do {
            // Convert the map to Data
            let data = try JSONEncoder().encode(timeEntriesMap)
            UserDefaults.standard.set(data, forKey: "timeMap")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
        
    func loadMapData() {
        do {
            if let savedData = UserDefaults.standard.data(forKey: "timeMap") {
                timeEntriesMap = try JSONDecoder().decode([String: TimerEntry].self, from: savedData)
                print("Loaded timeEntriesMap:", timeEntriesMap)
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    
    func startTimer(for title: String) {
        print("startTimer called for:",title)
        // Updates elapsed time every second.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let currentTime = Date()
            let startTime = self.timeEntriesMap[title]?.startTime
            self.timeEntriesMap[title]?.elapsedTime = currentTime.timeIntervalSince(startTime!)
        }
    }
    
    func addEntry() {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle, startTime: Date())
        timeEntriesMap[newEntryTitle] = newEntry
        startTimer(for: newEntryTitle) // Start the timer for the new entry
        newEntryTitle = ""
        saveMapData()
    }

    func resetTimer(for key: String) {
        timeEntriesMap[key]?.startTime = Date()
        saveMapData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        saveMapData()
    }
    
    func timeString(from elapsedTime: TimeInterval) -> String {
        print("timeEntries map =", timeEntriesMap)
        let days = Int(elapsedTime) / 86400
        let hours = (Int(elapsedTime) % 86400) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    func startTimers() {
        for key in timeEntriesMap.keys{
            startTimer(for: key)
        }
    }
}
