//
//  User.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI

// Model for each timer entry
struct TimerEntry : Codable{
    let title: String
    var startTime: Date
    var elapsedTime: TimeInterval = 0
    var history: [perItemTimerEntry]?
}

struct perItemTimerEntry : Codable, Hashable{
    var elapsedTime : TimeInterval
    var resetReason : String
}
