//
//  time_counter_watchApp.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

@main
struct time_counter_watch_Watch_AppApp: App {
    let viewModel = UserViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
