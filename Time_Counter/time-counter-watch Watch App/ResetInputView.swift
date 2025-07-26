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
    var onSubmitPlusPause: () -> Void
    var onCancel: () -> Void
    
//    var body: some View {
//        VStack(spacing: 8) {
//            Text("Reason")
//                .font(.caption)
//            
//            TextField("Type...", text: $userReason)
//                .controlSize(.mini)
//            
//            Divider()
//            
//            HStack(spacing: 4) {
//                Button("Reset") {
//                    onSubmit()
//                }
//                Button("Reset + Pause") {
//                    onSubmitPlusPause()
//                }
//            }
//            .buttonStyle(.bordered)
//            .controlSize(.mini)
//            
//            Button("Cancel", role: .cancel) {
//                onCancel()
//            }
//            .buttonStyle(.bordered)
//            .controlSize(.mini)
//        }
//        .padding(6)
//    }
//    var body: some View {
//        List {
//            Section(header: Text("Enter reason")) {
//                TextField("Reason", text: $userReason)
//            }
//            VStack{
//                Button("Reset", action: onSubmit)
//                    .buttonStyle(.borderedProminent)
//                    .controlSize(.mini)
//                Button("Reset + Pause", action: onSubmitPlusPause)
//                    .buttonStyle(.borderedProminent)
//                    .controlSize(.mini)
//                Button("Cancel", role: .cancel, action: onCancel)
//                    .buttonStyle(.bordered)
//                    .controlSize(.mini)
//            }
//            .frame(maxWidth: .infinity, alignment: .center)
//        }
//    }
    var body: some View {
        List {
            Section(header: Text("Enter reason")) {
                TextField("Reason", text: $userReason)
                    .multilineTextAlignment(.center)
            }

            Section {
                VStack(spacing: 4) {
                    Button("Reset") {
                        onSubmit()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)

                    Button("Reset + Pause") {
                        onSubmitPlusPause()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)

                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
