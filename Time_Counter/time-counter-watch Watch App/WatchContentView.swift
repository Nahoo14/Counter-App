//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: UserViewModel
    @StateObject var connectivity = Connectivity.shared
    
    @State private var path: [String] = []
    @State private var userReason = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 4) {
                List {
                    ForEach(viewModel.timeEntriesMap.keys.sorted(), id: \.self) { key in
                        if let entry = viewModel.timeEntriesMap[key] {
                            let isPaused = entry.isPaused
                            TimerRowView(
                                key: key,
                                entry: entry,
                                resetButton: {
                                    resetButton(for: key) as! AnyView
                                },
                                timeString: viewModel.timeStringEntries(for: entry, isPaused: isPaused ?? false)
                            )
                        }
                    }
                }
                .padding(.leading, 0.1)
            }
            .navigationDestination(for: String.self) { key in
                ResetInputView(
                    key: key,
                    userReason: $userReason,
                    onSubmit: {
                        viewModel.resetTimer(for: key, reason: userReason, resetTime: Date())
                        path.removeLast()
                    },
                    onCancel: {
                        path.removeLast()
                    }
                )
            }
        }
        .onChange(of: connectivity.receivedData) {
            viewModel.updateTimeEntriesMap(connectivity.receivedData)
        }
        .background(
            ZStack {
                Image("Seedling")
                    .resizable()
                    .scaledToFill()
                Color.black.opacity(0.5)
            }
        )
    }
   
    @State private var selectedKey = ""
    // removeCounter defines the view for the remove button.
    func resetButton(for key:String)-> some View {
        let isPaused = viewModel.timeEntriesMap[key]?.isPaused ?? false
        if isPaused{
            return AnyView(Button(action: {
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.red)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .onTapGesture{
                        selectedKey = key
                        viewModel.resumeTimer(for: key)
                    }
            }
            )}
        return AnyView(Button(action: {
        }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture {
                    userReason = ""
                    path.append(key)
                }
        })
    }
}

let viewModel = UserViewModel()

#Preview {
    ContentView(viewModel: viewModel)
}
