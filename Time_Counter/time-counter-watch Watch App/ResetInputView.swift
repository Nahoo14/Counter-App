//
//  ReasonInputView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 6/29/25.
//
import SwiftUI

struct ResetInputView: View {
    let key: String
    @Binding var userReason: String
    var onSubmit: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            Text("Enter reason")
            TextField("Reason", text: $userReason)
            HStack {
                Button("Reset") {
                    onSubmit()
                }
                Spacer()
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            }
        }
        .padding()
    }
}
