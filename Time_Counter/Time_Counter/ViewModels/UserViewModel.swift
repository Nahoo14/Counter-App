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
    
    
    func startTimer(for title: String) {
        print("startTimer called for:",title)
        // Updates elapsed time every second.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let currentTime = Date()
            let startTime = self.timeEntriesMap[title]?.startTime
            self.timeEntriesMap[title]?.elapsedTime = currentTime.timeIntervalSince(startTime!)
            self.timeEntriesMap[title]?.average = self.calculateAverage(for: title)
        }
    }
    
    func addEntry(newEntryTitle: String, startTime: Date) {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle, startTime: startTime, average: 0)
        timeEntriesMap[newEntryTitle] = newEntry
        startTimer(for: newEntryTitle) // Start the timer for the new entry
        saveMapData()
    }

    func resetTimer(for key: String, reason: String) {
        if var entry = timeEntriesMap[key] {
            let newHistory = perItemTimerEntry(startTime: entry.startTime, endTime: Date(), elapsedTime: entry.elapsedTime, resetReason: reason)
            if entry.history?.isEmpty ?? true {
                entry.history = [newHistory]
            } else {
                entry.history?.append(newHistory)
            }
            entry.startTime = Date()
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        saveMapData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        saveMapData()
    }
    
    func timeString(from elapsedTime: TimeInterval) -> String {
        // print("timeEntries map =", timeEntriesMap)
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
    
    func addRule(rule : String, for title: String){
        timeEntriesMap[title]?.rules = rule
        saveMapData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules // Return empty string if no rule exists
    }
}
