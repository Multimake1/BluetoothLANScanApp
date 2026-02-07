//
//  Models.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import Foundation

enum DeviceType: String, Codable {
    case bluetooth
    case lan
}

enum ConnectionStatus: String, Codable {
    case disconnected
    case connecting
    case connected
    case failed
}

struct BluetoothDevice: Identifiable, Codable {
    let id: UUID
    let peripheralUUID: UUID
    var name: String?
    var rssi: Int
    var status: ConnectionStatus
    var lastSeen: Date
    
    init(id: UUID = UUID(),
         peripheralUUID: UUID,
         name: String?,
         rssi: Int,
         status: ConnectionStatus,
         lastSeen: Date = Date()) {
        self.id = id
        self.peripheralUUID = peripheralUUID
        self.name = name
        self.rssi = rssi
        self.status = status
        self.lastSeen = lastSeen
    }
}

struct LANDevice: Identifiable, Codable {
    let id: UUID
    var ipAddress: String
    var macAddress: String?
    var hostname: String?
    var vendor: String?
    var lastSeen: Date
    
    init(id: UUID = UUID(),
         ipAddress: String,
         macAddress: String? = nil,
         hostname: String? = nil,
         vendor: String? = nil,
         lastSeen: Date = Date()) {
        self.id = id
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.hostname = hostname
        self.vendor = vendor
        self.lastSeen = lastSeen
    }
}

struct NetworkScan: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    var bluetoothDevices: [BluetoothDevice]
    var lanDevices: [LANDevice]
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         bluetoothDevices: [BluetoothDevice] = [],
         lanDevices: [LANDevice] = []) {
        self.id = id
        self.timestamp = timestamp
        self.bluetoothDevices = bluetoothDevices
        self.lanDevices = lanDevices
    }
}

enum DeviceItem: Identifiable {
    case bluetooth(BluetoothDevice)
    case lan(LANDevice)
    
    var id: UUID {
        switch self {
        case .bluetooth(let device):
            return device.id
        case .lan(let device):
            return device.id
        }
    }
    
    var displayName: String {
        switch self {
        case .bluetooth(let device):
            return device.name ?? "Неизвестное устройство"
        case .lan(let device):
            return device.hostname ?? device.ipAddress
        }
    }
    
    var details: String {
        switch self {
        case .bluetooth(let device):
            return "RSSI: \(device.rssi) dB"
        case .lan(let device):
            return device.macAddress ?? "MAC не определен"
        }
    }
    
    var type: DeviceType {
        switch self {
        case .bluetooth:
            return .bluetooth
        case .lan:
            return .lan
        }
    }
}
