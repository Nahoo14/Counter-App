//
//  ContentView.swift
//  time-counter-watch Watch App
//
//  Created by Baby Tinishu on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: UserViewModel
    @StateObject var connectivity = Connectivity()
    
    var body: some View {
        let timeEntriesMap = connectivity.receivedData
        VStack(alignment: .leading){
            Text("Streaks")
                .padding([.top, .leading], 0.1)
            List {
                ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                    }
                }
            }
        }
        .background(
            ZStack{
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
