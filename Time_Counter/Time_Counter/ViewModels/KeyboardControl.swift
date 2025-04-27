//
//  KeyboardControl.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func hideKeyboard(){
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

func preloadKeyboard() {
    DispatchQueue.global(qos: .background).async {
        // Simulate interaction
        _ = ""
    }
}
