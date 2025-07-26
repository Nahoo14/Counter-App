//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import WatchConnectivity

class UserViewModel: ObservableObject {

    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    @Published var timePulse = Date()
    
    var connectivity = Connectivity.shared
    
    private var timer : Timer? = nil
    
    var Data = DataManager()
    
    func startUpdatingTime() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.timePulse = Date() // Update triggers SwiftUI refresh
            }
        }
    }
    
    func stopUpdatingTime() {
        timer?.invalidate()
        timer = nil
    }
    
    init() {
        timeEntriesMap = Data.loadMapData()
        notifyOther()
    }
    
    func saveData(){
        Data.timeEntriesMap = timeEntriesMap
        Data.saveMapData()
    }
    
    func addEntry(newEntryTitle: String, startTime: Date) {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle, startTime: startTime, lastUpdated: Date())
        timeEntriesMap[newEntryTitle] = newEntry
        notifyOther()
        saveData()
    }
    
    func resumeTimer(for key: String){
        timeEntriesMap[key]?.isPaused = false
        timeEntriesMap[key]?.startTime = Date()
        timeEntriesMap[key]?.lastUpdated = Date()
        notifyOther()
        saveData()
    }
    
    // calculateAverage returns the average time per entry.
    func calculateAverage(for title: String) -> TimeInterval{
        let timeEntry = timeEntriesMap[title]
        var elapsed = Date().timeIntervalSince(timeEntry!.startTime)
        let historyCount = (timeEntry?.history?.count ?? 0) + 1
        if let history = timeEntry?.history {
            for entry in history {
                elapsed += entry.elapsedTime
            }
        }
        return elapsed / Double(historyCount)
    }
    
    // longestStreak returns the longest streak.
    func longestStreak(for title: String) -> TimeInterval{
        let timeEntry = timeEntriesMap[title]
        var longest = Date().timeIntervalSince(timeEntry!.startTime)
        if let history = timeEntry?.history {
            for entry in history {
                if entry.elapsedTime > longest{
                    longest = entry.elapsedTime
                }
            }
        }
        return longest
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
            entry.lastUpdated = Date()
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        notifyOther()
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
            entry.lastUpdated = Date()
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        notifyOther()
        saveData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        notifyOther()
        saveData()
    }
    
    
    func timeString(from elapsedTime: TimeInterval) -> String {
        let days = Int(elapsedTime) / 86400
        let hours = (Int(elapsedTime) % 86400) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    func timeStringEntries(for entry: TimerEntry, isPaused : Bool) -> String {
        if isPaused{
            return "Paused"
        }
        let elapsed = Date().timeIntervalSince(entry.startTime)
        let days = Int(elapsed) / 86400
        let hours = (Int(elapsed) % 86400) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        let timeText = days > 0
        ? String(format: "%d d\n%02d h\n%02d:%02d", days, hours, minutes, seconds)
        : String(format: "%02d h\n%02d:%02d", hours, minutes, seconds)
        return timeText
    }
    
    func addRule(rule : String, for title: String){
        timeEntriesMap[title]?.rules = rule
        saveData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules // Return empty string if no rule exists
    }
    
    func updateTimeEntriesMap(_ newMap: [String: TimerEntry]) {
        // check last updated time and update here.
        var updated = newMap
        for (key,val) in newMap{
            if let existing = timeEntriesMap[key]{
                if val.lastUpdated > existing.lastUpdated{
                    updated[key] = val
                    print("Updated key \(key)")
                }
            }
        }
        timeEntriesMap = updated
        saveData()
    }
    
    func notifyWatch() {
        print("sending \(timeEntriesMap) to watch.")
        connectivity.sendUpdateToWatch(timeEntriesMap: self.timeEntriesMap)
    }
    
    func notifyiOS() {
        print("sending \(timeEntriesMap) to ios")
        connectivity.sendUpdateToiOS(timeEntriesMap: self.timeEntriesMap)
    }
    
    func notifyOther(){
#if os(iOS)
        notifyWatch()
#else
        notifyiOS()
#endif
    }
}
