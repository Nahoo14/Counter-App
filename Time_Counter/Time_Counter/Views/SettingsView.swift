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
    @State private var showingNotificationSheet: Bool = false
    
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
                // Custom Backgrounds row
                Button(action: {
                    if viewModel.hasProPurchased {
                        showImagePicker = true
                    } else {
                        viewModel.purchaseProVersion()
                    }
                }) {
                    HStack {
                        Text("Custom backgrounds")
                        Spacer()
                        Image(systemName: viewModel.hasProPurchased ? "photo.fill" : "lock.fill")
                            .foregroundColor(viewModel.hasProPurchased ? .blue : .secondary)
                    }
                }

                // Daily Reminders row
                Button(action: {
                    if viewModel.hasProPurchased {
                        showingNotificationSheet = true
                    } else {
                        viewModel.purchaseProVersion()
                    }
                }) {
                    HStack {
                        Text("Daily Reminders")
                        Spacer()
                        Image(systemName: viewModel.hasProPurchased ? (viewModel.notificationsEnabled ? "bell.fill" : "bell.slash.fill") : "lock.fill")
                            .foregroundColor(viewModel.hasProPurchased ? (viewModel.notificationsEnabled ? .green : .red) : .secondary)
                    }
                }
                .sheet(isPresented: $showingNotificationSheet) {
                    VStack(spacing: 16) {
                        Toggle(isOn: Binding(get: { viewModel.notificationsEnabled }, set: { newVal in
                            if newVal {
                                viewModel.checkAndEnableNotifications(at: viewModel.notificationTime)
                            } else {
                                viewModel.disableNotifications()
                            }
                        })) {
                            Text("Enable Daily Reminders")
                        }

                        // Existing reminder times
                        VStack(alignment: .leading) {
                            Text("Reminder times")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if viewModel.notificationTimes.isEmpty {
                                Text("No reminder times set")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(Array(viewModel.notificationTimes.enumerated()), id: \.offset) { idx, time in
                                    HStack {
                                        Text(DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short))
                                        Spacer()
                                            Button(role: .destructive) {
                                                viewModel.notificationTimes.remove(at: idx)
                                                if viewModel.notificationsEnabled {
                                                    viewModel.rescheduleNotificationsIfEnabled()
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                    }
                                }
                            }
                        }

                        // Add new time
                        DatePicker("", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                        Button("Add Time") {
                            // dedupe by hour and minute
                            let compsNew = Calendar.current.dateComponents([.hour, .minute], from: viewModel.notificationTime)
                            let exists = viewModel.notificationTimes.contains { comps in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: comps)
                                return c.hour == compsNew.hour && c.minute == compsNew.minute
                            }
                            if !exists {
                                viewModel.notificationTimes.append(viewModel.notificationTime)
                                if viewModel.notificationsEnabled {
                                    // reschedule with full list
                                    viewModel.rescheduleNotificationsIfEnabled()
                                }
                            }
                        }

                        Spacer()
                        Button("Done") { showingNotificationSheet = false }
                    }
                    .padding()
                    .alert(isPresented: $viewModel.showNotificationsDeniedAlert) {
                        Alert(title: Text("Notifications Disabled"), message: Text("Notifications are disabled for this app in Settings. Please enable them in system Settings to receive reminders."), primaryButton: .default(Text("Open Settings"), action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }), secondaryButton: .cancel())
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

                // Purchase/Restore actions
                if !viewModel.hasProPurchased {
                    Button {
                        viewModel.purchaseProVersion()
                    } label: {
                        Text("Purchase Pro \(viewModel.availableProducts.first?.displayPrice ?? "$0.99")")
                    }
                    Button("Restore Purchases") {
                        viewModel.restorePurchases()
                    }
                } else {
                    Button("Remove Purchase (Test)") { viewModel.hasProPurchased = false }
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
