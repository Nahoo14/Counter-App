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
            #if os(iOS)
            TabView {
                ContentView(viewModel: viewModel)
                    .tabItem { Label("Timers", systemImage: "timer") }
                
                SettingsView(viewModel: viewModel)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
            #elseif os(watchOS)
            ContentView(viewModel: viewModel)
            #endif
        }
    }
}
