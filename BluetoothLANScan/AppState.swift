//
//  AppState.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var isBluetoothAuthorized = false
    @Published var isNetworkAuthorized = false
    @Published var showNetworkPermissionAlert = false
    
    @Published var lastScanDate: Date?
    @Published var totalDevicesFound = 0
    
    @Published var useMockServices = true {
        didSet {
            NetworkServicesFactory.shared.mode = .mock //если менять, то и в NetworkServiceFactory
        }
    }
        
    /*init() {
        NetworkServicesFactory.shared.mode = .real
    }*/
}
