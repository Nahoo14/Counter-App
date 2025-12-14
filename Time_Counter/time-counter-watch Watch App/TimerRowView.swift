//
//  TimerRowView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 6/29/25.
//

import SwiftUI

struct TimerRowView: View {
    let key: String
    let entry: TimerEntry
    let resetButton: () -> AnyView
    let timeString: String

    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            Spacer()
            if entry.type == .timer {
                Text(timeString)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            } else {
                // Daily Check-In representation: three recent days as dots (green = success, red = fail)
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { idx in
                        // Placeholder: if history exists mark green else red; you can replace with real per-day data
                        Circle().fill(idx % 2 == 0 ? Color.green : Color.red).frame(width: 10, height: 10)
                    }
                }
            }
            resetButton()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
        .foregroundColor(.white)
        .listRowBackground(Color.clear)
    }
}
