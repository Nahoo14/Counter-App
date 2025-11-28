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

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Make tab icons more visible
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.label

        // Make tab text bold + visible
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            TabView {
                ContentView(viewModel: viewModel)
                    .tabItem { Label("Timers", systemImage: "timer") }

                SettingsView(viewModel: viewModel)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
            .preferredColorScheme(viewModel.selectedTheme.colorScheme)

            #elseif os(watchOS)
            ContentView(viewModel: viewModel)
            #endif
        }
    }
}
