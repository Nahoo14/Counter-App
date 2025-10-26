//
//  EditReasonView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 10/25/25.
//

import SwiftUI

struct EditResetReasonView: View {
    @ObservedObject var viewModel: UserViewModel
    var key: String
    var index: Int
    var entry: perItemTimerEntry

    @State private var resetReason: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter reset reason", text: $resetReason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()
            }
            .navigationTitle("Edit Reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateResetReason(for: key, at: index, with: resetReason)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                resetReason = entry.resetReason
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
