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
        VStack(alignment: .leading){
            Text("Streaks")
                .padding(.leading, 10)
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
