//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: UserViewModel
    @State private var path = NavigationPath()
    @State private var userReason = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            let sortedKeys = viewModel.timeEntriesMap.keys.sorted()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedKeys, id: \.self) { key in
                        if let entry = viewModel.timeEntriesMap[key] {
                            let timeText = viewModel.timeStringEntries(for: entry, isPaused: entry.isPaused ?? false)
                            TimerRowView(
                                key: key,
                                entry: entry,
                                resetButton: { viewModel.resetButton(for: key, path: $path, userReason: $userReason) },
                                timeString: timeText
                            )
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
            .navigationDestination(for: String.self) { key in
                ResetInputView(
                    key: key,
                    userReason: $userReason,
                    onSubmit: {
                        viewModel.resetTimer(for: key, reason: userReason, resetTime: Date())
                        path.removeLast()
                    },
                    onSubmitPlusPause: {
                        viewModel.resetAndPauseTimer(for: key, reason: userReason, resetTime: Date())
                        path.removeLast()
                    },
                    onCancel: { path.removeLast() }
                )
            }
        }
        .onAppear { viewModel.startUpdatingTime() }
        .onDisappear { viewModel.stopUpdatingTime() }
        .onChange(of: viewModel.timeEntriesMap) { _ in
            viewModel.connectivity.syncState(timeEntriesMap: viewModel.timeEntriesMap)
        }
        .background(Color.black.opacity(0.5))
    }
}
