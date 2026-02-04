//
//  ScanViewModel.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import Foundation
import Combine
import CoreBluetooth

class NetworkScannerViewModel: ObservableObject {
    @Published var bluetoothDevices: [BluetoothDevice] = []
    @Published var lanDevices: [LANDevice] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var currentStatus = "Готов к сканированию"
    @Published var selectedTab = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        
    }
    
    
}

