//
//  EntryView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 3/29/25.
//

import SwiftUI

// EntryView defines the view for the counter entry fields.

struct EntryView: View {
    @ObservedObject var viewModel: UserViewModel
    @State var newEntryTitle = ""
    @State var showRulesEntry = false
    @State var showDateEntry = false
    @State var selectedDate = Date()
    @State var rules = ""
    
    var body: some View {
        HStack {
            TextField("Enter streak title", text: $newEntryTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .animation(.easeInOut(duration: 0.2), value: newEntryTitle)
                .onAppear {
                    preloadKeyboard() // Preload keyboard on app start
                }
            // Entry added here
            Button(action: {
                showDateEntry = true
            }) {
                Text("Start Counter")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showDateEntry) {
                VStack{
                    Text("Select start time")
                        .font(.headline)
                        .foregroundColor(.red)
                    DatePicker("", selection: $selectedDate, in: ...Date(),displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .frame(width: 200)
                }
                HStack{
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        // exit sheet
                        showDateEntry = false
                    }
                    .buttonStyle(.borderedProminent)
                    //.tint(.red)
                    Spacer()
                    Button("Continue") {
                        showRulesEntry = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .alert("Add initial notes",isPresented: $showRulesEntry){
                    TextField("rules", text: $rules)
                    Button("Submit"){
                        viewModel.addEntry(newEntryTitle: newEntryTitle, startTime: selectedDate)
                        viewModel.addRule(rule: rules, for: newEntryTitle)
                        // Reset state
                        showRulesEntry = false
                        showDateEntry = false
                        newEntryTitle = ""
                        rules = ""
                        selectedDate = Date()
                        UIApplication.shared.endEditing()
                    }
                    Button("Cancel", role: .cancel) {
                        showRulesEntry = false
                        UIApplication.shared.endEditing()
                    }
                }
            }
            .padding()
        }
    }
}
