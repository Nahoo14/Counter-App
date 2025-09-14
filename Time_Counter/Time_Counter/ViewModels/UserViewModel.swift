//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import WatchConnectivity
import Combine

class UserViewModel: ObservableObject {
    
    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    @Published var timePulse = Date()
    
    var connectivity = Connectivity.shared
    
    private var timer : Timer? = nil
    
    var Data = DataManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 1. Load local data first
        timeEntriesMap = Data.loadMapData()
        Connectivity.shared.onReceiveState = { [weak self] remoteMap in
                self?.updateTimeEntriesMap(remoteMap) // uses your lastUpdated merge logic
        }
    }
    
    func startUpdatingTime() {
        timer?.invalidate()
        
        let now = Date()
        let nextFullSecond = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970) + 1)
        let delay = nextFullSecond.timeIntervalSince(now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.timePulse = Date()  // initial aligned tick
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timePulse = Date()
            }
            RunLoop.current.add(self.timer!, forMode: .common)
        }
    }
    
    func stopUpdatingTime() {
        timer?.invalidate()
        timer = nil
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
        let years = Int(elapsedTime) / 31_536_000
        let days = (Int(elapsedTime) % 31_536_000) / 86400
        let hours = (Int(elapsedTime) % 86400) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        if years > 0 {
            return "\(years)y \(days)d \(hours)h \(minutes)m \(seconds)s"
        } else if days > 0 {
            return "\(days)d \(hours)h \(minutes)m \(seconds)s"
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func timeStringEntries(for entry: TimerEntry, isPaused: Bool) -> String {
        if isPaused {
            return "Paused"
        }

        let elapsed = Date().timeIntervalSince(entry.startTime)
        let totalSeconds = Int(elapsed)
        
        let years = totalSeconds / 31_536_000
        let days = (totalSeconds % 31_536_000) / 86_400
        let hours = (totalSeconds % 86_400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        let timeText: String
        if years > 0 {
            timeText = String(format: "%d y\n%d d\n%02d h\n%02d:%02d", years, days, hours, minutes, seconds)
        } else {
            timeText = String(format: "%d d\n%02d h\n%02d:%02d", days, hours, minutes, seconds)
        }
        return timeText
    }
    
    func addRule(rule : String, for title: String){
        timeEntriesMap[title]?.rules = rule
        timeEntriesMap[title]?.lastUpdated = Date()
        saveData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules // Return empty string if no rule exists
    }
    
    func updateTimeEntriesMap(_ newMap: [String: TimerEntry]) {
        // check last updated time and update here.
        var updated = newMap
        for (key,newVal) in newMap{
            if let existing = timeEntriesMap[key]{
                if newVal.lastUpdated > existing.lastUpdated{
                    updated[key] = newVal
                    print("Updated key \(key)")
                }else{
                    updated[key] = existing
                }
            }
        }
        timeEntriesMap = updated
        saveData()
    }
    
    func notifyOther(){
        connectivity.syncState(timeEntriesMap: timeEntriesMap)
        // connectivity.sendRealtimeUpdate(timeEntriesMap: timeEntriesMap)
    }
}
