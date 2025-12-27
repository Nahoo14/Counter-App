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
import UserNotifications

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
        Task { [weak self] in
            await self?.fetchProducts(); await self?.checkEntitlementsAsync()
        }
        Connectivity.shared.onReceiveState = { [weak self] remoteMap in
            self?.updateTimeEntriesMap(remoteMap)
        }
        // update notification permission status
        updateNotificationStatus()
        // Listen for transaction updates to grant entitlements
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == self?.productIDs.first {
                    DispatchQueue.main.async { [weak self] in self?.hasProPurchased = true }
                }
            }
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
    @Published var isRestoring: Bool = false

    // Notification permissions and scheduling
    @Published var notificationsAuthorized: Bool = false
    @Published var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notifications_enabled") {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled") }
    }
    @Published var notificationTime: Date = UserDefaults.standard.object(forKey: "notifications_time") as? Date ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var notificationTimes: [Date] = (UserDefaults.standard.array(forKey: "notifications_times") as? [Double])?.map { Date(timeIntervalSince1970: $0) } ?? [] {
        didSet {
            let arr = notificationTimes.map { $0.timeIntervalSince1970 }
            UserDefaults.standard.set(arr, forKey: "notifications_times")
            if notificationsEnabled {
                // reschedule with new times
                scheduleNotificationsForAllDailyEntries(at: notificationTimes)
            }
        }
    }

    func updateNotificationStatus() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsAuthorized = granted
                completion(granted)
            }
        }
    }

    @Published var showNotificationsDeniedAlert: Bool = false

    func checkAndEnableNotifications(at time: Date) {
        // Save desired time up front
        notificationTime = time
        UserDefaults.standard.set(time, forKey: "notifications_time")
        // Ensure single time is also in list
        if !notificationTimes.contains(where: { Calendar.current.isDate($0, inSameDayAs: time) }) {
            notificationTimes.append(time)
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                // schedule immediately
                DispatchQueue.main.async {
                    self.notificationsEnabled = true
                }
                self.scheduleNotificationsForAllDailyEntries(at: self.notificationTimes)
            case .denied:
                // cannot enable; prompt user to open Settings
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                    self.showNotificationsDeniedAlert = true
                }
            case .notDetermined:
                // request authorization
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        self.notificationsAuthorized = granted
                        if granted {
                            self.notificationsEnabled = true
                        } else {
                            self.notificationsEnabled = false
                            self.showNotificationsDeniedAlert = true
                        }
                    }
                    if granted {
                        self.scheduleNotificationsForAllDailyEntries(at: self.notificationTimes)
                    }
                }
            @unknown default:
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                }
            }
        }
    }

    func disableNotifications() {
        notificationsEnabled = false
        let center = UNUserNotificationCenter.current()
        // Remove all app-specific daily check identifiers
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("yesNoDaily_") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // Public helper to reschedule with current notificationTimes (used after add/remove)
    func rescheduleNotificationsIfEnabled() {
        guard notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                // clear existing yesNoDaily_... requests before scheduling
                center.getPendingNotificationRequests { requests in
                    let ids = requests.filter { $0.identifier.hasPrefix("yesNoDaily_") }.map { $0.identifier }
                    if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
                    self.scheduleNotificationsForAllDailyEntries(at: self.notificationTimes)
                }
            } else if settings.authorizationStatus == .denied {
                DispatchQueue.main.async { self.showNotificationsDeniedAlert = true }
            }
        }
    }

    // Debug helpers
    func printPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            print("Pending notification requests:\n\(requests.map { $0.identifier + " @ " + (($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents.description ?? "no trigger") }.joined(separator: "\n"))")
        }
    }

    func forceRescheduleNow() {
        // For testing: clear and reschedule
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("yesNoDaily_") }.map { $0.identifier }
            if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
            self.scheduleNotificationsForAllDailyEntries(at: self.notificationTimes)
        }
    }

    private func scheduleNotificationsForAllDailyEntries(at times: [Date]) {
        let center = UNUserNotificationCenter.current()
        // remove existing app-level yesNoDaily_time_... requests first
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("yesNoDaily_time_") }.map { $0.identifier }
            if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
            // schedule one repeating notification per configured time
            for (idx, time) in times.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "Daily Check"
                content.body = "Time to check on your streaks."
                content.sound = .default
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                dateComponents.second = 0
                let id = "yesNoDaily_time_\(idx)"
                let repeatingTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let repeatingRequest = UNNotificationRequest(identifier: id, content: content, trigger: repeatingTrigger)
                center.add(repeatingRequest) { error in
                    if let err = error { print("Failed to schedule repeating notification for time index \(idx): \(err)") }
                }
            }
        }
    }

    private func nextOccurrence(hour: Int, minute: Int, after date: Date) -> Date? {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        if let next = cal.nextDate(after: date, matching: comps, matchingPolicy: .nextTime) {
            return next
        }
        // fallback to tomorrow at that time
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: date) {
            return cal.nextDate(after: tomorrow, matching: comps, matchingPolicy: .nextTime)
        }
        return nil
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
            DispatchQueue.main.async { [weak self] in
                self?.availableProducts = fetched
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
        Task { [weak self] in
            guard let self = self else { return }
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
// Note: Transaction.updates listener in init ensures all purchases are handled reliably.
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(_):
                        DispatchQueue.main.async { [weak self] in self?.hasProPurchased = true }
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
        Task { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isRestoring = true }
            do {
                // Ask the App Store to re-send transactions to refresh entitlements
                try? await AppStore.sync()
                var found = false
                for try await verification in Transaction.currentEntitlements {
                    switch verification {
                    case .verified(let transaction):
                        if transaction.productID == productIDs.first {
                            found = true
                            DispatchQueue.main.async { self.hasProPurchased = true }
                        }
                    case .unverified(let transaction, let error):
                        print("Unverified transaction for \(transaction.productID): \(error)")
                    }
                }
                if !found {
                    // No current entitlement found; do not alter hasProPurchased here (keeps any local state)
                }
            } catch {
                print("Restore failed: \(error)")
            }
            DispatchQueue.main.async { self.isRestoring = false }
        }
    }

    // Optional quick entitlement check on launch
    func checkEntitlements() {
        Task { [weak self] in
            guard let self = self else { return }
            for await verificationResult in Transaction.currentEntitlements {
                switch verificationResult {
                case .verified(let transaction):
                    if transaction.productID == productIDs.first {
                        DispatchQueue.main.async { [weak self] in self?.hasProPurchased = true }
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
                        DispatchQueue.main.async { [weak self] in self?.hasProPurchased = true }
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
    
    func addEntry(newEntryTitle: String, startTime: Date, type: CounterType = .timer) {
        guard !newEntryTitle.isEmpty else { return }
        let newEntry = TimerEntry(type: type, title: newEntryTitle, startTime: startTime, rules: nil, history: nil, isPaused: nil, lastUpdated: Date())
        timeEntriesMap[newEntryTitle] = newEntry
        notifyOther()
        saveData()
    }

    // MARK:

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
