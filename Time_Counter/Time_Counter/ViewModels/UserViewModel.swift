//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    //@Published var timerEntries: [TimerEntry] = []
    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    @Published var newEntryTitle: String = ""
    
    func startTimer(for title: String) {
        timeEntriesMap[title]?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
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
    }

    func resetTimer(for key: String) {
        timeEntriesMap[key]?.startTime = Date()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    func startTimers() {
        for index in timeEntriesMap.keys {
            startTimer(for: index)
        }
    }
}
