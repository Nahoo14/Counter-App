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
    @State private var showingNotificationSheet: Bool = false
    
    var body: some View {
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
                        Text("Custom background")
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
                                let sortedTimes = viewModel.notificationTimes.sorted { t1, t2 in
                                    let c1 = Calendar.current.dateComponents([.hour, .minute], from: t1)
                                    let c2 = Calendar.current.dateComponents([.hour, .minute], from: t2)
                                    if c1.hour != c2.hour { return (c1.hour ?? 0) < (c2.hour ?? 0) }
                                    return (c1.minute ?? 0) < (c2.minute ?? 0)
                                }
                                ForEach(Array(sortedTimes.enumerated()), id: \.offset) { idx, time in
                                    HStack {
                                        Text(DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short))
                                        Spacer()
                                        Button(role: .destructive) {
                                            if let originalIndex = viewModel.notificationTimes.firstIndex(where: { comps in
                                                let c = Calendar.current.dateComponents([.hour, .minute], from: comps)
                                                let ct = Calendar.current.dateComponents([.hour, .minute], from: time)
                                                return c.hour == ct.hour && c.minute == ct.minute
                                            }) {
                                                viewModel.notificationTimes.remove(at: originalIndex)
                                                if viewModel.notificationsEnabled {
                                                    viewModel.rescheduleNotificationsIfEnabled()
                                                }
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
                
                // Purchase/Restore actions
                if !viewModel.hasProPurchased {
                    Button {
                        viewModel.purchaseProVersion()
                    } label: {
                        Text("Purchase Pro \(viewModel.availableProducts.first?.displayPrice ?? "$0.99")")
                    }
                    Button(action: { viewModel.restorePurchases() }) {
                        if viewModel.isRestoring {
                            HStack { ProgressView().scaleEffect(0.8); Text("Restoring...") }
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                    .disabled(viewModel.isRestoring)
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
}
