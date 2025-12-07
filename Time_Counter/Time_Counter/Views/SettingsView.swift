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
        let proFeatures = ["Custom backgrounds"]
        List {
            Section("Light Mode") {
                Picker("Mode", selection: $viewModel.selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
            }

            Section("Pro Upgrade") {
                ForEach(proFeatures, id: \.self) { feature in
                    HStack {
                        Text(feature)
                        Spacer()
                        Image(systemName: viewModel.hasProPurchased ? "lock.open" : "lock.fill")
                            .foregroundColor(viewModel.hasProPurchased ? .green : .secondary)
                    }
                }

                if viewModel.hasProPurchased {
                    Button("Choose Custom Background") {
                        showImagePicker = true
                    }
                    Button("Remove Purchase (Test)") {
                        viewModel.hasProPurchased = false
                    }
                } else {
                    Button {
                        viewModel.purchaseProVersion()
                    } label: {
                        Text("Purchase Pro \(viewModel.availableProducts.first?.displayPrice ?? "$0.99")")
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
                            viewModel.hasProPurchased = true
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
        .task {
            await viewModel.fetchProducts()
        }
    }
}
