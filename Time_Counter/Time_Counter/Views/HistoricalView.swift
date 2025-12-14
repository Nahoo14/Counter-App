import SwiftUI

struct HistoricalView: View {
    var history: [perItemTimerEntry]?
    @ObservedObject var viewModel: UserViewModel
    var key: String
    
    @State private var selectedEntryIndex: Int? = nil
    @State private var showEditReasonSheet: Bool = false
    
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
    
    private func isPausedForKey() -> Bool {
        viewModel.timeEntriesMap[key]?.isPaused ?? false
    }
    private func currentValueForKey() -> TimeInterval {
        if isPausedForKey() {
            return Date().timeIntervalSince(viewModel.timeEntriesMap[key]?.lastUpdated ?? Date())
        }
        return Date().timeIntervalSince(viewModel.timeEntriesMap[key]?.startTime ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("\(key) history")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black))
                    
                    VStack {
                        VStack {
                            statRow(title: "Average:", value: "\(viewModel.timeString(from: viewModel.calculateAverage(for: key))) (per reset)")
                            statRow(title: "Longest:", value: viewModel.timeString(from: viewModel.longestStreak(for: key)))
                            statRow(
                                title: isPausedForKey() ? "Paused for:" : "Current:",
                                value: viewModel.timeString(from: currentValueForKey())
                            )
                        }
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.black))
                        .padding(8)
                        
                        Spacer()
                        
                        List {
                            if let history = history, !history.isEmpty {
                                ForEach(Array(history.enumerated()), id: \.1) { index, item in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Reset \(index + 1) notes")
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
                }
                .background(
                    Group {
                        if let uiImage = viewModel.customBackgroundImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                        } else {
                            Image("Flower")
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                        }
                    }
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
}
