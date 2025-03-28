//
//  MooChatApp.swift
//  MooChat
//
//  Created by Muxuan Li on 2025-03-27.
//

import SwiftUI

@main
struct MooChatApp: App {
    @AppStorage("serverURL") private var serverURL = "http://localhost:8080"
    
    init() {
        // Configure app transport security
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.register(defaults: [
                "\(bundleIdentifier).NSAppTransportSecurity": [
                    "NSAllowsArbitraryLoads": true,
                    "NSAllowsLocalNetworking": true
                ]
            ])
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
