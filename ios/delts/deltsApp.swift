//
//  deltsApp.swift
//  delts
//
//  Created by Apoorv Darshan on 22/05/26.
//

import RevenueCat
import SwiftUI

@main
struct deltsApp: App {
    init() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: TipStore.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
