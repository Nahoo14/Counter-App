import SwiftUI

struct HistoricalView: View {
    var history: [perItemTimerEntry]?
    @ObservedObject var viewModel: UserViewModel
    var key: String

    @State private var selectedEntryIndex: Int? = nil
    @State private var showEditReasonView = false

    var body: some View {
        ZStack {
            VStack {
                Text("\(key) history")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                let average = viewModel.calculateAverage(for: key)
                let longest = viewModel.longestStreak(for: key)
                let entry = viewModel.timeEntriesMap[key]!
                let current = Date().timeIntervalSince(entry.startTime)
                let endTime = Date().timeIntervalSince(entry.lastUpdated)
                let currentIsPaused = entry.isPaused

                VStack {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Average: ")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("\(viewModel.timeString(from: average)) (per reset)")
                            .font(.body)
                            .foregroundColor(.yellow)
                            .bold()
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Longest: ")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(viewModel.timeString(from: longest))
                            .font(.body)
                            .foregroundColor(.yellow)
                            .bold()
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text(currentIsPaused ?? false ? "Paused for: " : "Current: ")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(currentIsPaused ?? false ? viewModel.timeString(from: endTime) : viewModel.timeString(from: current))
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntryIndex = index
                                showEditReasonView = true
                            }
                        }
                    } else {
                        Text("No history available")
                            .font(.system(size: 15))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .background(
                Image("Flower")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
            )
        }
        .sheet(isPresented: $showEditReasonView) {
            if let index = selectedEntryIndex,
               let entry = history?[index] {
                EditResetReasonView(
                    viewModel: viewModel,
                    key: key,
                    index: index,
                    entry: entry
                )
            }
        }
    }
}
