//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        Text("Streaks")
        List {
            ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                }
            }
        }
    }
}

let viewModel = UserViewModel()

#Preview {
    ContentView(viewModel: viewModel)
}
