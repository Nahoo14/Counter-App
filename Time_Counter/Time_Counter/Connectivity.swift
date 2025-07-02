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
    
    @Published var receivedText = ""
    @Published var receivedData: [String: TimerEntry] = [:]
    private var pendingData: [String: TimerEntry] = [:]
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
                    print("watchOS received updated map: \(decoded)")
                    self.receivedData = decoded
                }
            } catch {
                print("watchOS failed to decode timeEntriesMap: \(error)")
            }
        } else {
            print("pplicationContext didn't contain expected data")
        }
    }
    
    // sends update to ios
    func sendUpdateToiOS(timeEntriesMap: [String: TimerEntry]) {
        if WCSession.default.isReachable {
            do {
                let data = try JSONEncoder().encode(timeEntriesMap)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    WCSession.default.sendMessage(json, replyHandler: { response in
                        print("Sent data: \(timeEntriesMap) to iOS, response:", response)
                    }, errorHandler: { error in
                        print("Error sending to iOS:", error)
                    })
                }
            } catch {
                print("Failed to encode timeEntriesMap for iOS:", error)
            }
        } else {
            print("iOS not reachable, saving for retry")
            pendingData = timeEntriesMap
        }
    }
    
    // sends update to watchos
    func sendUpdateToWatch(timeEntriesMap: [String: TimerEntry]) {
        guard WCSession.default.activationState == .activated else {
            print("WCSession not activated yet — storing for retry")
            pendingData = timeEntriesMap
            return
        }
        
        do {
            let data = try JSONEncoder().encode(timeEntriesMap)
            try WCSession.default.updateApplicationContext(["timeEntriesMap": data])
            print("Sent data: \(timeEntriesMap) to Watch using applicationContext")
        } catch {
            print("Failed to send update: \(error)")
            pendingData = timeEntriesMap
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            if pendingData != [:]{
#if os(iOS)
#else
                sendUpdateToiOS(timeEntriesMap: pendingData)
                print("availaibility changed, sending pendingData: \(pendingData)")
#endif
            }
        }
    }
}
