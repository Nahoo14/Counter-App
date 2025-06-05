//
//  RulesView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 3/30/25.
//

import SwiftUI

// rulesView defines the view for the per-counter rule entry.
struct rulesView : View {
    @ObservedObject var viewModel: UserViewModel
    @State private var isEditing: Bool = false
    @State var rules: String = ""
    var key: String
    
    init(viewModel: UserViewModel, key: String) {
        self.viewModel = viewModel
        self.key = key
        _rules = State(initialValue: viewModel.getRules(for: key) ?? "") // Initialize with existing rule
    }
    
    var body: some View{
        VStack(alignment: .leading, spacing: 16) {
            CustomTextEditor(text: $rules)
                .padding([.leading, .trailing], 8)
                .background(
                    Color(UIColor.systemGray6) // Adaptive background color
                )
                .cornerRadius(8)
            Spacer()
            
            Button(action: {
                viewModel.addRule(rule: rules, for: key)
                UIApplication.shared.endEditing()
            }) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .background(
            Image("Water_Fall")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)
        )
        .navigationTitle("notes")
        // Navigate to the per item view.
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: historicalView(history: viewModel.timeEntriesMap[key]?.history, viewModel: viewModel, key: key)) {
                    Text("History")
                        .foregroundColor(.blue).bold()
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(key) notes")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
    }
}
