//
//  Time_CounterApp.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 10/26/24.
//

import SwiftUI

@main
struct TimeCounterApp: App {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: viewModel)
                    .tabItem { Label("Timers", systemImage: "timer") }
                
                SettingsView(viewModel: viewModel)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
            .preferredColorScheme(viewModel.selectedTheme.colorScheme)
        }
    }
}
