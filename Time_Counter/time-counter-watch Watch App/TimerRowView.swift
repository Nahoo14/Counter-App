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
            Text(timeString)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
            resetButton()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
        .foregroundColor(.white)
        .listRowBackground(Color.clear)
    }
}
