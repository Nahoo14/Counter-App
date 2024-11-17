//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    @Published var timerEntries: [TimerEntry] = []
    @Published var timeEntriesMap : [String : TimerEntry] = [:]
    @Published var newEntryTitle: String = ""
    
    func startTimer(for index: Int) {
        timerEntries[index].timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timerEntries[index].elapsedTime += 1
        }
    }
    
    func addEntry() {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle)
        timerEntries.append(newEntry)
        newEntryTitle = ""
        startTimer(for: timerEntries.count - 1) // Start the timer for the new entry
    }

    func resetTimer(for index: Int) {
        print("resetTimer called with index : \(index) timerEntries : \(timerEntries)")
        if timerEntries.indices.contains(index) {
            timerEntries[index].elapsedTime = 0 // Reset the elapsed time
        }
    }
    
    // Bug is probably here
    func deleteEntry(at offsets: IndexSet) {
        print("deleteEntry called at offset: \(offsets) for timerEntries: \(timerEntries)")
        for index in offsets {
            timerEntries[index].timer?.invalidate() // Stop the timer
        }
        timerEntries.remove(atOffsets: offsets)
    }

    func timeString(from timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
    
    private func startTimers() {
        for index in timerEntries.indices {
            startTimer(for: index)
        }
    }
}
