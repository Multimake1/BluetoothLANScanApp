//
//  MockBluetoothService.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import Foundation
import Combine
import CoreBluetooth

final class MockBluetoothService {
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var bluetoothState: CBManagerState = .poweredOn
    @Published var networkStatus: NetworkStatus = .ready
    
    private var timer: Timer?
    
    private func addMockDevice(name: String, rssi: Int) {
        let device = BluetoothDevice(
            peripheralUUID: UUID(),
            name: name,
            rssi: rssi,
            status: .disconnected
        )
        
        discoveredDevices.append(device)
        print("MockBluetoothService: Найдено устройство \(name), RSSI: \(rssi)")
    }
}

extension MockBluetoothService: IBluetoothServiceProtocol {
    func startScan() {
        print("MockBluetoothService: Начинаем сканирование Bluetooth")
        
        isScanning = true
        scanProgress = 0.0
        discoveredDevices = []
        networkStatus = .scanning
        
        var progress: Double = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            progress += 0.02
            self.scanProgress = min(progress, 1.0)
            
            if progress >= 0.2 && self.discoveredDevices.count < 1 {
                self.addMockDevice(name: "iPhone 13", rssi: -45)
            }
            if progress >= 0.4 && self.discoveredDevices.count < 2 {
                self.addMockDevice(name: "AirPods Pro", rssi: -55)
            }
            if progress >= 0.6 && self.discoveredDevices.count < 3 {
                self.addMockDevice(name: "Apple Watch", rssi: -65)
            }
            if progress >= 0.8 && self.discoveredDevices.count < 4 {
                self.addMockDevice(name: "Smart TV", rssi: -70)
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                self.isScanning = false
                
                let result = NetworkStatus.ScanResult(
                    deviceCount: self.discoveredDevices.count,
                    duration: 5.0,
                    foundDevices: self.discoveredDevices.count
                )
                
                self.networkStatus = .completed(result)
                print("MockBluetoothService: Сканирование завершено, найдено \(self.discoveredDevices.count) устройств")
            }
        }
    }
    
    func stopScan() {
        print("MockBluetoothService: Останавливаем сканирование")
        
        timer?.invalidate()
        timer = nil
        isScanning = false
        
        let result = NetworkStatus.ScanResult(
            deviceCount: discoveredDevices.count,
            duration: 2.5,
            foundDevices: discoveredDevices.count
        )
        
        networkStatus = .completed(result)
    }
    
    func connectToDevice(device: BluetoothDevice) {
        print("MockBluetoothService: Подключаемся к устройству \(device.name ?? "Unknown")")
        
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index].status = .connected
        }
    }
    
    func disconnectFromDevice(device: BluetoothDevice) {
        print("MockBluetoothService: Отключаемся от устройства \(device.name ?? "Unknown")")
        
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index].status = .disconnected
        }
    }
}
