//
//  BluetoothService.swift
//  BluetoothLANScan
//
//  Created by Арсений on 05.02.2026.
//

import Foundation
import CoreBluetooth
import Combine

protocol IBluetoothServiceProtocol {
    var discoveredDevices: [BluetoothDevice] { get }
    var isScanning: Bool { get }
    var scanProgress: Double { get }
    var bluetoothState: CBManagerState { get }
    var networkStatus: NetworkStatus { get }
    
    func startScan()
    func stopScan()
    func connectToDevice(device: BluetoothDevice)
    func disconnectFromDevice(device: BluetoothDevice)
}

final class BluetoothService: NSObject {
    @Published private(set) var discoveredDevices: [BluetoothDevice] = []
    @Published private(set) var isScanning = false
    @Published private(set) var scanProgress: Double = 0.0
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var networkStatus: NetworkStatus = .ready
    
    private var centralManager: CBCentralManager?
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]
    private var scanTimer: Timer?
    private var progressTimer: Timer?
    private let scanTimeout: TimeInterval = 15.0
    private let progressUpdateInterval: TimeInterval = 0.1
    private var scanStartTime: Date?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        updateNetworkStatusBasedOnBluetoothState()
    }
    
    deinit {
        stopScan()
    }
    
    private func startProgressTimer() {
        let totalUpdates = scanTimeout / progressUpdateInterval
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: progressUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isScanning else { return }
            
            self.scanProgress = min(self.scanProgress + (1.0 / totalUpdates), 1.0)
            
            if self.scanProgress >= 1.0 {
                self.stopScan()
            }
        }
    }
    
    private func handleScanTimeout() {
        networkStatus = .error(.timeout)
        stopScan()
    }
    
    private func updateNetworkStatusBasedOnBluetoothState() {
        switch bluetoothState {
        case .poweredOn:
            networkStatus = .ready
        case .poweredOff:
            networkStatus = .error(.bluetoothDisabled)
        case .unauthorized, .unsupported:
            networkStatus = .error(.permissionDenied)
        default:
            networkStatus = .ready
        }
    }
    
    private func updateDeviceStatus(peripheral: CBPeripheral, status: ConnectionStatus) {
        if let index = discoveredDevices.firstIndex(where: { $0.peripheralUUID == peripheral.identifier }) {
            discoveredDevices[index].status = status
            discoveredDevices[index].lastSeen = Date()
        }
    }
}

extension BluetoothService: IBluetoothServiceProtocol {
    func startScan() {
        guard bluetoothState == .poweredOn else {
            if bluetoothState == .poweredOff {
                networkStatus = .error(.bluetoothDisabled)
            } else {
                networkStatus = .error(.permissionDenied)
            }
            return
        }
        
        guard networkStatus.canStartScan else {
            return
        }
        
        networkStatus = .preparing
        isScanning = true
        scanProgress = 0.0
        discoveredDevices.removeAll()
        scanStartTime = Date()
        
        networkStatus = .scanning
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        startProgressTimer()
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanTimeout, repeats: false) { [weak self] _ in
            self?.handleScanTimeout()
        }
    }
    
    func stopScan() {
        guard isScanning else { return }
        
        centralManager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        
        isScanning = false
        scanProgress = 1.0
        
        let duration = scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let result = NetworkStatus.ScanResult(
            deviceCount: discoveredDevices.count,
            duration: duration,
            foundDevices: discoveredDevices.count
        )
        
        networkStatus = .completed(result)
        scanStartTime = nil
    }
    
    func connectToDevice(device: BluetoothDevice) {
        guard let peripheral = connectedPeripherals[device.peripheralUUID] else { return }
        
        if peripheral.state != .connected {
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func disconnectFromDevice(device: BluetoothDevice) {
        guard let peripheral = connectedPeripherals[device.peripheralUUID] else { return }
        
        if peripheral.state == .connected || peripheral.state == .connecting {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        updateNetworkStatusBasedOnBluetoothState()
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {
        
        let deviceName = peripheral.name ??
                        advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
                        "Неизвестное устройство"
        
        let status: ConnectionStatus = peripheral.state == .connected ? .connected : .disconnected
        
        let device = BluetoothDevice(
            id: UUID(),
            peripheralUUID: peripheral.identifier,
            name: deviceName,
            rssi: RSSI.intValue,
            status: status,
            lastSeen: Date()
        )
        
        if let index = discoveredDevices.firstIndex(where: { $0.peripheralUUID == peripheral.identifier }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
        
        if connectedPeripherals[peripheral.identifier] == nil {
            connectedPeripherals[peripheral.identifier] = peripheral
        }
        
        discoveredDevices.sort { $0.rssi > $1.rssi }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didConnect peripheral: CBPeripheral) {
        updateDeviceStatus(peripheral: peripheral, status: .connected)
    }
    
    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        updateDeviceStatus(peripheral: peripheral, status: .failed)
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        updateDeviceStatus(peripheral: peripheral, status: .disconnected)
    }
}
