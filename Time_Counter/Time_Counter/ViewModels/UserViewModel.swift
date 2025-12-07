//
//  UserViewModel.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/10/24.
//

import SwiftUI
import Combine
import UIKit
import StoreKit

class UserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var timeEntriesMap: [String: TimerEntry] = [:]
    @Published var timePulse = Date()
    
    @Published var selectedTheme: AppTheme = .system {
        didSet {
            saveThemeToUserDefaults()
        }
    }
    
    var connectivity = Connectivity.shared
    
    private var timer: Timer? = nil
    private var dataManager = DataManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        timeEntriesMap = dataManager.loadMapData()       // Load saved timers
        loadThemeFromUserDefaults()               // Load saved theme
        loadProPurchase()
        Task { await fetchProducts(); await checkEntitlementsAsync() }
        Connectivity.shared.onReceiveState = { [weak self] remoteMap in
            self?.updateTimeEntriesMap(remoteMap)
        }
    }
    
    // MARK: - Theme Persistence
    private func saveThemeToUserDefaults() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "app_theme")
    }
    
    private func loadThemeFromUserDefaults() {
        if let saved = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: saved) {
            selectedTheme = theme
        }
    }

    private func loadProPurchase() {
        hasProPurchased = UserDefaults.standard.bool(forKey: "has_pro_purchase")
    }

    // MARK: - Purchases / Entitlements
    @Published var hasProPurchased: Bool = false {
        didSet { UserDefaults.standard.set(hasProPurchased, forKey: "has_pro_purchase") }
    }

    func saveCustomBackgroundImage(_ image: UIImage) {
        if let data = image.pngData() {
            let url = getDocumentsDirectory().appendingPathComponent("custom_background.png")
            try? data.write(to: url)
        }
    }

    func loadCustomBackgroundImage() -> UIImage? {
        let url = getDocumentsDirectory().appendingPathComponent("custom_background.png")
        return UIImage(contentsOfFile: url.path)
    }

    var customBackgroundImage: UIImage? { loadCustomBackgroundImage() }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Purchases
    @Published var availableProducts: [Product] = []
    private let productIDs: [String] = ["com.nahom.streaktimer.proversion"]

    func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
            DispatchQueue.main.async {
                self.availableProducts = fetched
                print("Fetched products count: \(fetched.count), ids: \(fetched.map({ $0.id }))")
            }
            // Log details for missing products
            let returnedIDs = Set(fetched.map { $0.id })
            let missing = productIDs.filter { !returnedIDs.contains($0) }
            if !missing.isEmpty {
                print("Missing product IDs from response: \(missing)")
            }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    func purchaseProVersion() {
        Task {
            // Ensure products are loaded
            if availableProducts.isEmpty {
                await fetchProducts()
            }
            print("Available products before purchase: \(availableProducts.map({ $0.id }))")
            print("Expected productIDs: \(productIDs)")
            guard let product = availableProducts.first(where: { $0.id == productIDs.first }) else {
                print("No product available to purchase; availableProducts: \(availableProducts.map({ $0.id }))")
                return
            }

            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(_):
                        DispatchQueue.main.async { self.hasProPurchased = true }
                    case .unverified(_, let error):
                        print("Transaction unverified: \(error)")
                    }
                case .userCancelled, .pending:
                    print("Purchase cancelled or pending: \(result)")
                    break
                default:
                    break
                }
            } catch {
                print("Purchase failed: \(error)")
            }
        }
    }

    func restorePurchases() {
        Task {
            do {
                for await verification in Transaction.currentEntitlements {
                    switch verification {
                    case .verified(let transaction):
                        if transaction.productID == productIDs.first {
                            DispatchQueue.main.async { self.hasProPurchased = true }
                        }
                    case .unverified(let transaction, let error):
                        // Unverified transactions are ignored for entitlement granting, but log for debugging
                        print("Unverified transaction for \(transaction.productID): \(error)")
                    }
                }
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }

    // Optional quick entitlement check on launch
    func checkEntitlements() {
        Task {
            for await verificationResult in Transaction.currentEntitlements {
                switch verificationResult {
                case .verified(let transaction):
                    if transaction.productID == productIDs.first {
                        DispatchQueue.main.async { self.hasProPurchased = true }
                    }
                case .unverified(let transaction, let error):
                    print("Unverified transaction for \(transaction.productID): \(error)")
                }
            }
        }
    }

    // Async wrapper to call checkEntitlements from init
    func checkEntitlementsAsync() async {
        do {
            for try await verificationResult in Transaction.currentEntitlements {
                switch verificationResult {
                case .verified(let transaction):
                    if transaction.productID == productIDs.first {
                        DispatchQueue.main.async { self.hasProPurchased = true }
                    }
                case .unverified(let transaction, let error):
                    print("Unverified transaction for \(transaction.productID): \(error)")
                }
            }
        } catch {
            print("Entitlement check failed: \(error)")
        }
    }
    
    // MARK: - Timer Handling
    func startUpdatingTime() {
        timer?.invalidate()
        let now = Date()
        let nextFullSecond = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970) + 1)
        let delay = nextFullSecond.timeIntervalSince(now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.timePulse = Date()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timePulse = Date()
            }
            RunLoop.current.add(self.timer!, forMode: .common)
        }
    }
    
    func stopUpdatingTime() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Data Handling
    func saveData() {
        dataManager.timeEntriesMap = timeEntriesMap
        dataManager.saveMapData()
    }
    
    func notifyOther() {
        connectivity.syncState(timeEntriesMap: timeEntriesMap)
    }
    
    func addEntry(newEntryTitle: String, startTime: Date) {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(title: newEntryTitle, startTime: startTime, lastUpdated: Date())
        timeEntriesMap[newEntryTitle] = newEntry
        notifyOther()
        saveData()
    }
    
    func resumeTimer(for key: String) {
        timeEntriesMap[key]?.isPaused = false
        timeEntriesMap[key]?.startTime = Date()
        timeEntriesMap[key]?.lastUpdated = Date()
        notifyOther()
        saveData()
    }
    
    func resetTimer(for key: String, reason: String, resetTime: Date) {
        guard var entry = timeEntriesMap[key] else { return }
        let newHistory = perItemTimerEntry(
            startTime: entry.startTime,
            endTime: resetTime,
            elapsedTime: resetTime.timeIntervalSince(entry.startTime),
            resetReason: reason
        )
        entry.history = (entry.history ?? []) + [newHistory]
        entry.startTime = resetTime
        entry.lastUpdated = Date()
        timeEntriesMap[key] = entry
        notifyOther()
        saveData()
    }
    
    func resetAndPauseTimer(for key: String, reason: String, resetTime: Date) {
        guard var entry = timeEntriesMap[key] else { return }
        let newHistory = perItemTimerEntry(
            startTime: entry.startTime,
            endTime: resetTime,
            elapsedTime: resetTime.timeIntervalSince(entry.startTime),
            resetReason: reason
        )
        entry.history = (entry.history ?? []) + [newHistory]
        entry.isPaused = true
        entry.lastUpdated = Date()
        timeEntriesMap[key] = entry
        notifyOther()
        saveData()
    }
    
    func deleteEntry(at key: String) {
        timeEntriesMap.removeValue(forKey: key)
        notifyOther()
        saveData()
    }
    
    // MARK: - Stats
    func calculateAverage(for title: String) -> TimeInterval {
        guard let timeEntry = timeEntriesMap[title] else { return 0 }
        var elapsed = timeEntry.isPaused ?? false ? 0 : Date().timeIntervalSince(timeEntry.startTime)
        let historyCount = (timeEntry.history?.count ?? 0) + (timeEntry.isPaused ?? false ? 0 : 1)
        if let history = timeEntry.history {
            for entry in history {
                elapsed += entry.elapsedTime
            }
        }
        return historyCount > 0 ? elapsed / Double(historyCount) : 0
    }
    
    func longestStreak(for title: String) -> TimeInterval {
        guard let timeEntry = timeEntriesMap[title] else { return 0 }
        var longest = timeEntry.isPaused ?? false ? 0 : Date().timeIntervalSince(timeEntry.startTime)
        if let history = timeEntry.history {
            for entry in history {
                if entry.elapsedTime > longest {
                    longest = entry.elapsedTime
                }
            }
        }
        return longest
    }
    
    // MARK: - Reset Button Helper (watchOS safe)
    func resetButton(
        for key: String,
        path: Binding<NavigationPath>,
        userReason: Binding<String>
    ) -> AnyView {
        let isPaused = timeEntriesMap[key]?.isPaused ?? false

        #if os(watchOS)
        // Small watchOS buttons
        if isPaused {
            return AnyView(Button {
                self.resumeTimer(for: key)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain))
        } else {
            return AnyView(Button {
                userReason.wrappedValue = ""
                path.wrappedValue.append(key)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain))
        }
        #else
        // iOS buttons
        if isPaused {
            return AnyView(Button {
                self.resumeTimer(for: key)
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(.red)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            })
        } else {
            return AnyView(Button {
                userReason.wrappedValue = ""
                path.wrappedValue.append(key)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(.red)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            })
        }
        #endif
    }
    
    // MARK: - Rename / Update Functions
    func renameStreak(oldKey: String, newKey: String) {
        guard let entry = timeEntriesMap.removeValue(forKey: oldKey) else { return }
        timeEntriesMap[newKey] = entry
        saveData()
        connectivity.syncState(timeEntriesMap: timeEntriesMap)
    }
    
    func updateResetReason(for key: String, at index: Int, with newReason: String) {
        guard var entry = timeEntriesMap[key] else { return }
        var historyArray = entry.history ?? []
        guard historyArray.indices.contains(index) else { return }
        historyArray[index].resetReason = newReason
        entry.history = historyArray
        timeEntriesMap[key] = entry
        saveData()
        connectivity.syncState(timeEntriesMap: timeEntriesMap)
    }
    
    func updateTimeEntriesMap(_ newMap: [String: TimerEntry]) {
        var updated = newMap
        for (key, newVal) in newMap {
            if let existing = timeEntriesMap[key] {
                updated[key] = newVal.lastUpdated > existing.lastUpdated ? newVal : existing
            }
        }
        timeEntriesMap = updated
        saveData()
    }
    
    func addRule(rule: String, for title: String) {
        timeEntriesMap[title]?.rules = rule
        timeEntriesMap[title]?.lastUpdated = Date()
        saveData()
    }
    
    func getRules(for key: String) -> String? {
        return timeEntriesMap[key]?.rules
    }
    
    // MARK: - Time Formatting
    func timeString(from elapsedTime: TimeInterval) -> String {
        let years = Int(elapsedTime) / 31_536_000
        let days = (Int(elapsedTime) % 31_536_000) / 86400
        let hours = (Int(elapsedTime) % 86400) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if years > 0 {
            return "\(years)y \(days)d \(hours)h \(minutes)m \(seconds)s"
        } else if days > 0 {
            return "\(days)d \(hours)h \(minutes)m \(seconds)s"
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func timeStringEntries(for entry: TimerEntry, isPaused: Bool) -> String {
        if isPaused { return "Paused" }
        let elapsed = Date().timeIntervalSince(entry.startTime)
        let totalSeconds = Int(elapsed)
        let years = totalSeconds / 31_536_000
        let days = (totalSeconds % 31_536_000) / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if years > 0 {
            return String(format: "%d y\n%d d\n%02d h\n%02d:%02d", years, days, hours, minutes, seconds)
        } else {
            return String(format: "%d d\n%02d h\n%02d:%02d", days, hours, minutes, seconds)
        }
    }
}
