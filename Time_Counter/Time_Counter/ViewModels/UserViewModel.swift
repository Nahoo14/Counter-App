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
    
    /*
    import Foundation

    let startTime = Date() // Start time
    let endTime = Date().addingTimeInterval(100000) // Simulate end time 100,000 seconds later

    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .hour, .minute, .second], from: startTime, to: endTime)

    print("Elapsed time: \(components.day ?? 0) days, \(components.hour ?? 0) hours, \(components.minute ?? 0) minutes, \(components.second ?? 0) seconds")

    */
    
    func startTimer(for title: String) {
        timeEntriesMap[title]?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timeEntriesMap[title]?.elapsedTime += 1
            //self.timeEntriesMap[title]?.elapsedTime = Date() - self.timeEntriesMap[title]?.startTime
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
        timeEntriesMap[key]?.elapsedTime = 0
    }
    
    func deleteEntry(at key: String) {
        //print("delete entry called for :", key)
        timeEntriesMap.removeValue(forKey: key)
    }

    func timeString(from timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
//        let calendar = Calendar.current
//        let startTime = timeEntriesMap[key]?.startTime
//        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: startTime!, to: Date())
//        return String("\(components.day ?? 0) days, \(components.hour ?? 0):\(components.minute ?? 0):\(components.second ?? 0)")
    }
    
    func startTimers() {
        for index in timeEntriesMap.keys {
            startTimer(for: index)
        }
    }
}
