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
    @StateObject var connectivity = Connectivity()
    
    private var timer : Timer? = nil
    
    var Data = DataManager()
    
    init() {
        timeEntriesMap = Data.loadMapData()

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
        notifyWatch()
        saveData()
    }
    
    func resumeTimer(for key: String){
        timeEntriesMap[key]?.isPaused=false
        timeEntriesMap[key]?.startTime=Date()
        saveData()
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
                self.timeEntriesMap[title]?.elapsedTime = 0
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
        notifyWatch()
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
            entry.elapsedTime = 0
            timeEntriesMap[key] = entry
        } else {
            print("No entry found for key: \(key)")
        }
        print("map after adding history", timeEntriesMap)
        notifyWatch()
        saveData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        notifyWatch()
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
    
    func timeStringEntries(for entry: TimerEntry) -> String {
        let elapsed = Date().timeIntervalSince(entry.startTime)
        let days = Int(elapsed) / 86400
        let hours = (Int(elapsed) % 86400) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    func addRule(rule : String, for title: String){
        timeEntriesMap[title]?.rules = rule
        saveData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules // Return empty string if no rule exists
    }
    
    func updateTimeEntriesMap(_ newMap: [String: TimerEntry]) {
        timeEntriesMap = newMap
        startTimers()
    }
    
    func notifyWatch() {
        connectivity.sendMessage(timeEntriesMap)
    }

}
