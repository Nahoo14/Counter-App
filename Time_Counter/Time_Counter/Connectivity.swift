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
        Task{
            @MainActor in
            if activationState == .activated{
                if session.isWatchAppInstalled{
                    self.receivedText = "Watch app is Installed."
                }
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
    func sendMessage(_ map: [String: TimerEntry]) {
        let session = WCSession.default

        guard session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(map)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                session.sendMessage(json) { response in
                    Task { @MainActor in
                        self.receivedText = "Received response: \(response)"
                    }
                } errorHandler: { error in
                    Task { @MainActor in
                        self.receivedText = "Error: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            print("Encoding error: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: [])
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: data)
                self.receivedData = decoded
                for (key, entry) in decoded {
                    print("Received \(key): \(entry.elapsedTime)")
                }

                replyHandler(["response": "Received time entries"])
            } catch {
                print("Decoding error: \(error)")
                replyHandler(["response": "Failed to decode"])
            }
        }
    }
}
