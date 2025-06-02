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
                        Text(viewModel.timeStringEntries(for: viewModel.timeEntriesMap[key]!))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
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
}

let viewModel = UserViewModel()

#Preview {
    ContentView(viewModel: viewModel)
}
