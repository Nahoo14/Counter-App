//
//  WatchConnector.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import Foundation
import WatchConnectivity

class Connectivity: NSObject, ObservableObject, WCSessionDelegate {
    @Published var receivedText = ""
    @Published var receivedData: [String: TimerEntry] = [:]
    private var lastSentMap: [String: TimerEntry] = [:]
    
    override init(){
        super.init()
        
        if WCSession.isSupported(){
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
#if os(iOS)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let encoded = session.receivedApplicationContext["timeEntriesMap"] as? Data {
            do {
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: encoded)
                DispatchQueue.main.async {
                    self.receivedData = decoded
                }
            } catch {
                print("Failed to decode applicationContext:", error)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
#else
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
    }
#endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: [])
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: data)
                self.receivedData = decoded
                print("received : \(decoded)")
                
                replyHandler(["response": "Received time entries"])
            } catch {
                print("Decoding error: \(error)")
                replyHandler(["response": "Failed to decode"])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let encoded = applicationContext["timeEntriesMap"] as? Data {
            do {
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: encoded)
                DispatchQueue.main.async {
                    self.receivedData = decoded
                }
            } catch {
                print("Failed to decode timeEntriesMap:", error)
            }
        }
    }
    
    func updateAndSend(timeEntriesMap: [String: TimerEntry]) {
        lastSentMap = timeEntriesMap
        sendUpdateToWatch()
    }
    
    func sendUpdateToWatch() {
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(lastSentMap)
            try WCSession.default.updateApplicationContext(["timeEntriesMap": data])
        } catch {
            print("Failed to send update: \(error)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            sendUpdateToWatch()
        }
    }
}
