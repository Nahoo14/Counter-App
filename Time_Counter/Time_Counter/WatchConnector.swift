//
//  WatchConnector.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    var session: WCSession

    override init() {
        self.session = WCSession.default
        super.init()
        session.delegate = self
        session.activate()
    }

    func sendTimeEntries(_ message: [String: Any]) {
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message:", error.localizedDescription)
            }
        } else {
            print("Watch is not reachable, using updateApplicationContext.")
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Failed to update context:", error.localizedDescription)
            }
        }
    }

    // Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
