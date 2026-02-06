//
//  config.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import Foundation

struct AppConfig {
    static func checkPlistKeys() {
        let keys = [
            "NSLocalNetworkUsageDescription",
            "NSBonjourServices",
            "NSBluetoothAlwaysUsageDescription"
        ]
        
        for key in keys {
            if let value = Bundle.main.object(forInfoDictionaryKey: key) {
                print("\(key): \(value)")
            } else {
                print("\(key): НЕ НАЙДЕН")
            }
        }
    }
}
