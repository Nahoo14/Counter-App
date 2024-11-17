//
//  User.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI

// Model for each timer entry
// Convert this to a map;
// {UUID : timerEntry}
struct TimerEntry: Identifiable {
    let id = UUID()
    let title: String
    var elapsedTime: TimeInterval = 0
    var timer: Timer?
}
