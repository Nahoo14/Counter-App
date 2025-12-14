//
//  User.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI

// Model for each timer entry
enum CounterType: String, Codable, CaseIterable {
    case timer

    var displayName: String {
        switch self {
        case .timer: return "Timer Counter"
        }
    }
    var description: String {
        switch self {
        case .timer: return "Track time-based streaks automatically."
        }
    }
}

struct TimerEntry : Codable, Equatable{
    var type: CounterType
    let title: String
    var startTime: Date 
    var rules: String?
    var history: [perItemTimerEntry]?
    var isPaused: Bool?
    var lastUpdated: Date
}

struct perItemTimerEntry : Codable, Hashable{
    var startTime : Date
    var endTime : Date
    var elapsedTime : TimeInterval
    var resetReason : String
}
