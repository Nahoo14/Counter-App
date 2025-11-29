//
//  SettingsView.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/2/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UserViewModel
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var bypassCode: String = ""
    
    var body: some View {
        List {
            Section(header: Text("Light Mode")) {
                Picker("Mode", selection: $viewModel.selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
            }

            Section(header: Text("Custom Background")) {
                if viewModel.hasCustomBackgroundPurchased {
                    Button("Choose Custom Background") {
                        showImagePicker = true
                    }
                    Button("Remove Purchase (Test)") {
                        viewModel.hasCustomBackgroundPurchased = false
                    }
                } else {
                    Button("Purchase") {
                        viewModel.purchaseCustomBackground()
                    }
                    Button("Restore Purchases") {
                        viewModel.restorePurchases()
                    }
                }

                HStack {
                    TextField("Test unlock code", text: $bypassCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Apply Code") {
                        if bypassCode == "TEST-UNLOCK-2025" {
                            viewModel.hasCustomBackgroundPurchased = true
                        }
                        bypassCode = ""
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let img = selectedUIImage {
                viewModel.saveCustomBackgroundImage(img)
                selectedUIImage = nil
            }
        }) {
            ImagePicker(selectedImage: $selectedUIImage)
        }
    }
}
