//
//  ScanHistoryDetailViewModel.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI
import Combine

class ScanHistoryDetailViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var searchText = ""
    @Published var bluetoothDevices: [BluetoothDeviceHistory] = []
    @Published var lanDevices: [LANDeviceHistory] = []
    
    let scan: ScanHistory
    private let dataManager = DataManager.shared
    
    var filteredBluetoothDevices: [BluetoothDeviceHistory] {
        if searchText.isEmpty {
            return bluetoothDevices
        } else {
            return bluetoothDevices.filter { device in
                device.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var filteredLANDevices: [LANDeviceHistory] {
        if searchText.isEmpty {
            return lanDevices
        } else {
            return lanDevices.filter { device in
                device.hostname?.localizedCaseInsensitiveContains(searchText) ?? false ||
                device.ipAddress?.localizedCaseInsensitiveContains(searchText) ?? false ||
                device.macAddress?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var scanDuration: String {
        String(format: "%.1fс", scan.duration)
    }
    
    var formattedTimestamp: String {
        DateFormatter.localizedString(
            from: scan.timestamp ?? Date(),
            dateStyle: .long,
            timeStyle: .short
        )
    }
    
    init(scan: ScanHistory) {
        self.scan = scan
    }
    
    func loadDevices() {
        bluetoothDevices = dataManager.fetchBluetoothDevices(scan: scan)
        lanDevices = dataManager.fetchLANDevices(scan: scan)
    }
    
    func convertToBluetoothDevice(_ history: BluetoothDeviceHistory) -> BluetoothDevice {
        BluetoothDevice(
            id: history.id ?? UUID(),
            peripheralUUID: UUID(),
            name: history.name,
            rssi: Int(history.rssi),
            status: .disconnected,
            lastSeen: history.timestamp ?? Date()
        )
    }
    
    func convertToLANDevice(_ history: LANDeviceHistory) -> LANDevice {
        LANDevice(
            id: history.id ?? UUID(),
            ipAddress: history.ipAddress ?? "0.0.0.0",
            macAddress: history.macAddress,
            hostname: history.hostname,
            vendor: history.vendor,
            lastSeen: history.timestamp ?? Date()
        )
    }
}
