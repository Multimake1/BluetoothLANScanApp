//
//  Models.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import Foundation
import CoreBluetooth

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
}

struct LANDevice: Identifiable, Codable {
    let id: UUID
    var ipAddress: String
    var macAddress: String?
    var hostname: String?
    var vendor: String?
    var lastSeen: Date
}

struct NetworkScan: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    var bluetoothDevices: [BluetoothDevice]
    var lanDevices: [LANDevice]
}
