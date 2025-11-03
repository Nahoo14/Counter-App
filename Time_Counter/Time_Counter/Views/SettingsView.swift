//
//  SettingsView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/2/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("App Theme")
                .font(.headline)
            
            Picker("Theme", selection: $viewModel.selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            
            HStack {
                Text("Primary")
                Circle()
                    .fill(viewModel.selectedTheme.primaryColor)
                    .frame(width: 24, height: 24)
                
                Text("Background")
                RoundedRectangle(cornerRadius: 4)
                    .fill(viewModel.selectedTheme.backgroundColor)
                    .frame(width: 24, height: 24)
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}
