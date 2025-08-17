//
//  WatchConnector.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import Foundation
import WatchConnectivity

class Connectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = Connectivity()
    
    @Published var receivedData: [String: TimerEntry] = [:]
    private var pendingData: [String: TimerEntry] = [:]
    
    private var session: WCSession {
        WCSession.default
    }
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
#if os(iOS)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
#else
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated, !pendingData.isEmpty {
            syncState(timeEntriesMap: pendingData)
            pendingData.removeAll()
        }
    }
#endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable, !pendingData.isEmpty {
            syncState(timeEntriesMap: pendingData)
            pendingData.removeAll()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: [])
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: data)
                self.receivedData = decoded
                print("Received message:", decoded)
                replyHandler(["response": "Received"])
                
                // Persist this state so both sides stay in sync
                try self.session.updateApplicationContext(["timeEntriesMap": data])
            } catch {
                print("Decoding error:", error)
                replyHandler(["response": "Failed to decode"])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let encoded = applicationContext["timeEntriesMap"] as? Data {
            do {
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: encoded)
                DispatchQueue.main.async {
                    print("Received appContext update:", decoded)
                    self.receivedData = decoded
                }
            } catch {
                print("Failed to decode applicationContext:", error)
            }
        }
    }
    
    // MARK: - Sync Logic
    
    /// Preferred method: guaranteed delivery, keeps last known state
    func syncState(timeEntriesMap: [String: TimerEntry]) {
        guard session.activationState == .activated else {
            print("WCSession not activated — storing for retry")
            pendingData = timeEntriesMap
            return
        }
        
        do {
            let data = try JSONEncoder().encode(timeEntriesMap)
            try session.updateApplicationContext(["timeEntriesMap": data])
            print("Synced state via applicationContext")
        } catch {
            print("Failed to sync state:", error)
            pendingData = timeEntriesMap
        }
    }
    
    /// Optional: real-time push, falls back to appContext
    func sendRealtimeUpdate(timeEntriesMap: [String: TimerEntry]) {
        guard session.activationState == .activated else {
            pendingData = timeEntriesMap
            return
        }
        
        do {
            let data = try JSONEncoder().encode(timeEntriesMap)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(json, replyHandler: { response in
                    print("Realtime sync success:", response)
                }, errorHandler: { error in
                    print("SendMessage failed:", error)
                })
            }
            
            // Always persist state too
            try session.updateApplicationContext(["timeEntriesMap": data])
        } catch {
            print("Encoding failed:", error)
            pendingData = timeEntriesMap
        }
    }
}
