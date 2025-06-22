//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    var connectivity = Connectivity.shared
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
        .background(
            ZStack {
                Image("Seedling")
                    .resizable()
                    .scaledToFill()
                Color.black.opacity(0.5)
            }
        )
    }
    
    @State private var showConfirmationDialogDelete = false
    @State private var selectedKey = ""
    @State private var userReason = ""

    
    // removeCounter defines the view for the remove button.
    func resetButton(for key:String)-> some View{
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
        return AnyView(Button(action: {
        }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture {
                    showConfirmationDialogDelete = true
                    selectedKey = key
                }
                .confirmationDialog("Are you sure you want to reset \(selectedKey)?", isPresented: $showConfirmationDialogDelete, titleVisibility: .visible) {
                    Button("Yes") {
                        viewModel.resetTimer(for: selectedKey, reason: userReason, resetTime: Date())
                    }
                    Button("Cancel", role: .cancel) { }
                }
        })
    }
}

let viewModel = UserViewModel()

#Preview {
    ContentView(viewModel: viewModel)
}

