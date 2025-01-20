//
//  User.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI

// Model for each timer entry
struct TimerEntry : Codable{
    let title: String
    var startTime: Date
    var elapsedTime: TimeInterval = 0
    var average: TimeInterval
    var rules: String?
    var history: [perItemTimerEntry]?
}

struct perItemTimerEntry : Codable, Hashable{
    var startTime : Date
    var endTime : Date
    var elapsedTime : TimeInterval
    var resetReason : String
}

// MARK: - CustomTextEditor
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.clear // Let the background be controlled by the parent
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) // Add padding
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.label // Adaptive text color for dark/light modes
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor

        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
