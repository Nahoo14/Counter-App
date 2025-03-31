//
//  HistoricalView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 3/30/25.
//

import SwiftUI

// historicalView displays the per counter historical view.
struct historicalView: View {
    var history : [perItemTimerEntry]?
    @ObservedObject var viewModel: UserViewModel
    var key: String
    var body: some View {
            ZStack{
                VStack {
                    Text("\(key) history")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                    let average = viewModel.calculateAverage(for: key)
                    let longest = viewModel.longestStreak(for: key)
                    let current = viewModel.timeEntriesMap[key]!.elapsedTime
                    VStack{
                        HStack {
                            Text("Average: ")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("\(viewModel.timeString(from: average)) (per reset)")
                                .font(.body)
                                .foregroundColor(.yellow)
                                .bold()
                        }
                        HStack {
                            Text("Longest: ")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(viewModel.timeString(from: longest))
                                .font(.body)
                                .foregroundColor(.yellow)
                                .bold()
                        }
                        HStack {
                            Text("Current: ")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(viewModel.timeString(from: current))
                                .font(.body)
                                .foregroundColor(.yellow)
                                .bold()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black)
                    )
                    .padding(8)
                        Spacer()
                        List {
                            if let history = history, !history.isEmpty {
                                ForEach(Array(history.enumerated()), id: \.1) { index, item in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Reset reason - \(index + 1): ")
                                            .font(.headline)
                                            .foregroundColor(.red) +
                                        Text(item.resetReason)
                                            .font(.body)
                                            .foregroundColor(.blue)
                                            .bold()
                                        
                                        Text("Duration: ")
                                            .font(.headline)
                                            .foregroundColor(.red) +
                                        Text("\(item.startTime) - \(item.endTime)")
                                        
                                        Text("Time elapsed: ")
                                            .font(.headline)
                                            .foregroundColor(.red) +
                                        Text(viewModel.timeString(from: item.elapsedTime))
                                            .font(.body)
                                            .foregroundColor(.green)
                                            .bold()
                                    }
                                    .padding(10)
                                    .listRowInsets(EdgeInsets())
                                }
                            } else {
                                Text("No history available")
                                    .font(.system(size: 15))
                            }
                        }
                        .scrollContentBackground(.hidden) // Remove the default list background
                }
                .background(
                    Image("Flower")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea(edges: .all)
                )
        }
    }
}
