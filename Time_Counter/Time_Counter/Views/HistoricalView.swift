import SwiftUI

struct HistoricalView: View {
    var history: [perItemTimerEntry]?
    @ObservedObject var viewModel: UserViewModel
    var key: String

    @State private var selectedEntryIndex: Int? = nil
    @State private var showEditReasonSheet: Bool = false

    var body: some View {
        NavigationStack {
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
                        statRow(title: "Average:", value: "\(viewModel.timeString(from: average)) (per reset)")
                        statRow(title: "Longest:", value: viewModel.timeString(from: longest))
                        statRow(
                            title: currentIsPaused ?? false ? "Paused for:" : "Current:",
                            value: currentIsPaused ?? false
                                ? viewModel.timeString(from: endTime)
                                : viewModel.timeString(from: current)
                        )
                    }
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.black))
                    .padding(8)

                    Spacer()

                    List {
                        if let history = history, !history.isEmpty {
                            ForEach(Array(history.enumerated()), id: \.1) { index, item in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Reset Reason - \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.red)

                                    Text(item.resetReason.isEmpty ? "Tap to add notes..." : item.resetReason)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 4)

                                    Text("Duration:")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text("\(item.startTime) - \(item.endTime)")

                                    Text("Time Elapsed:")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text(viewModel.timeString(from: item.elapsedTime))
                                        .font(.body)
                                        .foregroundColor(.green)
                                        .bold()
                                }
                                .padding(10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEntryIndex = index
                                    showEditReasonSheet = true
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
                        .ignoresSafeArea()
                )
            }
            .sheet(isPresented: $showEditReasonSheet) {
                if let idx = selectedEntryIndex,
                   let entry = history?[idx] {
                    EditResetReasonView(
                        viewModel: viewModel,
                        key: key,
                        entryIndex: idx,
                        entry: entry
                    )
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundColor(.red)
            Text(value)
                .font(.body)
                .foregroundColor(.yellow)
                .bold()
                .multilineTextAlignment(.leading)
        }
    }
}
