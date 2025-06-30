//
//  ResetTimeView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 3/30/25.
//

import SwiftUI

struct ResetTimeView: View {
    @State var selectedDate = Date()
    
    @Binding var showResetTime: Bool
    @Binding var selectedKey: String
    @Binding var showReasonAlert: Bool
    @Binding var userReason: String
    var viewModel: UserViewModel

    var body: some View {
        VStack(spacing: 20) {
            let entry = viewModel.timeEntriesMap[selectedKey]
            Text("Select reset time")
                .font(.headline)
                .foregroundColor(.red)
            
            DatePicker("", selection: $selectedDate, in: entry!.startTime...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .frame(width: 200)
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    showResetTime = false
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Continue") {
                    showReasonAlert = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding()
        .alert("Enter reason", isPresented: $showReasonAlert) {
            VStack {
                TextField("Reason", text: $userReason)
                VStack {
                    Button("Submit") {
                        viewModel.resetTimer(for: selectedKey, reason: userReason, resetTime: selectedDate)
                        showReasonAlert = false
                        showResetTime = false
                        selectedDate = Date()
                    }
                    Button("Submit + Pause"){
                        viewModel.resetAndPauseTimer(for: selectedKey, reason: userReason, resetTime: selectedDate)
                        showReasonAlert = false
                        showResetTime = false
                        selectedDate = Date()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }
}
