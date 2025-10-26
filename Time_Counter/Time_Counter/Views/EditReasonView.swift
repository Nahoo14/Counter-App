import SwiftUI

struct EditResetReasonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: UserViewModel
    var key: String
    var entryIndex: Int
    var entry: perItemTimerEntry

    @State private var resetReason: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit Notes")
                    .font(.title2)
                    .bold()

                Text("Use this space to record why the streak was reset or any reflections.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                TextEditor(text: $resetReason)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.updateResetReason(for: key, at: entryIndex, with: resetReason)
                        dismiss() // ✅ Only dismisses the sheet, stays on HistoricalView
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding()
            .navigationTitle("Edit Reset Reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                resetReason = entry.resetReason
            }
        }
    }
}

