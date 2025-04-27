//
//  WatchConnector.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 4/27/25.
//

import Foundation
import WatchConnectivity

class WatchConnector: NSObject, WCSessionDelegate{
    var session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
//    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
//    }
}
