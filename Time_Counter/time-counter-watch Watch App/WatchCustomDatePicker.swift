//
//  WatchCustomDatePicker.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 6/8/25.
//

import SwiftUI

struct StepByStepDateTimePickerView: View {
    enum PickerStep: Int, CaseIterable {
        case month, day, year, hour, minute, ampm
    }

    @State private var step: PickerStep = .month

    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedHour = {
        let h = Calendar.current.component(.hour, from: Date())
        return h == 0 || h == 12 ? 12 : h % 12
    }()
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var isAM = Calendar.current.component(.hour, from: Date()) < 12

    var body: some View {
        VStack(spacing: 10) {
            Text("Step \(step.rawValue + 1)/6")
                .font(.footnote)
            Text("Select \(stepLabel)")
                .font(.headline)

            currentPicker()
                .frame(height: 60)

            HStack {
                Button("Back") {
                    if step.rawValue > 0 {
                        step = PickerStep(rawValue: step.rawValue - 1)!
                    }
                }.disabled(step == .month)

                Button(step == .ampm ? "Confirm" : "Next") {
                    if step == .ampm {
                        // Confirm final selection
                        let finalDate = computeDate()
                        print("Selected: \(finalDate)")
                        // Send via WCSession here
                    } else {
                        step = PickerStep(rawValue: step.rawValue + 1)!
                    }
                }
            }
        }
        .padding()
    }

    var stepLabel: String {
        switch step {
        case .month: return "Month"
        case .day: return "Day"
        case .year: return "Year"
        case .hour: return "Hour"
        case .minute: return "Minute"
        case .ampm: return "AM / PM"
        }
    }

    @ViewBuilder
    func currentPicker() -> some View {
        switch step {
        case .month:
            Picker("Month", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { Text("\($0)") }
            }
        case .day:
            Picker("Day", selection: $selectedDay) {
                ForEach(1...31, id: \.self) { Text("\($0)") }
            }
        case .year:
            Picker("Year", selection: $selectedYear) {
                ForEach(2020...2030, id: \.self) { Text("\($0)") }
            }
        case .hour:
            Picker("Hour", selection: $selectedHour) {
                ForEach(1...12, id: \.self) { Text("\($0)") }
            }
        case .minute:
            Picker("Minute", selection: $selectedMinute) {
                ForEach(0...59, id: \.self) { Text(String(format: "%02d", $0)) }
            }
        case .ampm:
            Picker("AM/PM", selection: $isAM) {
                Text("AM").tag(true)
                Text("PM").tag(false)
            }
        }
    }

    func computeDate() -> Date? {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        var hour24 = selectedHour % 12
        if !isAM { hour24 += 12 }
        components.hour = hour24
        components.minute = selectedMinute
        return Calendar.current.date(from: components)
    }
}
