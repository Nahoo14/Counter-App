//
//  Time_CounterApp.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 10/26/24.
//

import SwiftUI

@main
struct Time_CounterApp: App {
    var userViewModel = UserViewModel()
    @StateObject private var watchConnector = WatchConnector()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel : userViewModel)
                .environmentObject(watchConnector)
        }
    }
}
