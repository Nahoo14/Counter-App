//
//  WatchConnector.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import Foundation
import WatchConnectivity

class Connectivity: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = Connectivity()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var onReceiveState: (([String: TimerEntry]) -> Void)?


    func syncState(timeEntriesMap: [String: TimerEntry]) {
        do {
            let data = try JSONEncoder().encode(timeEntriesMap)

            // Send via applicationContext (best effort, always delivered latest)
            try WCSession.default.updateApplicationContext(["timeEntriesMap": data])

            // Also send via message if reachable (instant if peer is active)
            if WCSession.default.isReachable {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                WCSession.default.sendMessage(dict, replyHandler: nil, errorHandler: nil)
            }

        } catch {
            print("Error encoding timeEntriesMap: \(error)")
        }
    }


    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: [])
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: data)

                onReceiveState?(decoded)

                replyHandler(["response": "Received time entries"])
            } catch {
                print("Decoding error: \(error)")
                replyHandler(["response": "Failed to decode"])
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String : Any]) {
        if let encoded = applicationContext["timeEntriesMap"] as? Data {
            do {
                let decoded = try JSONDecoder().decode([String: TimerEntry].self, from: encoded)

                DispatchQueue.main.async {
                    self.onReceiveState?(decoded)
                }
            } catch {
                print("Failed to decode timeEntriesMap: \(error)")
            }
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("WCSession activated: \(activationState)")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

