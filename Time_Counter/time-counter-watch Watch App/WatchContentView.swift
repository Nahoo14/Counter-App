//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var connectivity = Connectivity()
    @StateObject var viewModel = UserViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            List {
                ForEach(viewModel.timeEntriesMap.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                        Spacer()
                        let isPaused = viewModel.timeEntriesMap[key]?.isPaused ?? false
                        Text(viewModel.timeStringEntries(for: viewModel.timeEntriesMap[key]!, isPaused: isPaused))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                        resetButton(for: key)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
                    .foregroundColor(.white)
                    .listRowBackground(Color.clear)
                }
            }
            .padding([.leading], 0.1)
        }
        .onChange(of: connectivity.receivedData) {
            viewModel.updateTimeEntriesMap(connectivity.receivedData)
        }
        .fullScreenCover(isPresented: $showResetTime, onDismiss: {
            print("showResetTime = \(showResetTime)")
            print("Sheet dismissed")
        }) {
            ResetTimeView(
                showResetTime: $showResetTime,
                selectedKey: $selectedKey,
                showErrorAlert: $showErrorAlert,
                showReasonAlert: $showReasonAlert,
                userReason: $userReason,
                viewModel: viewModel
            )
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
    
    // resetButton variables
    @State private var showResetTime: Bool = false
    @State private var showReasonAlert = false
    @State private var selectedKey = ""
    @State private var userReason = ""
    @State private var showErrorAlert = false

    
    // resetButton defines the view for the reset button.
    func resetButton(for key: String)-> some View {
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
                        print("Resume pressed")
                    }
            }
            )}
        return AnyView( Button(action: {
        }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture{
                    showResetTime = true
                    selectedKey = key
                    print("showResetTime = \(showResetTime)")
                }
        })
    }
}

let viewModel = UserViewModel()

#Preview {
    ContentView(viewModel: viewModel)
}
