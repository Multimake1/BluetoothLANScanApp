//
//  MockLANService.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import Foundation
import Combine

class MockLANService {
    @Published var discoveredDevices: [LANDevice] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var networkStatus: NetworkStatus = .ready
    @Published var currentSSID: String? = "Test_WiFi_Network"
    
    private var timer: Timer?
    private let mockDevices = [
        LANDevice(ipAddress: "192.168.1.1", macAddress: "AA:BB:CC:DD:EE:FF", hostname: "Router", vendor: "TP-Link"),
        LANDevice(ipAddress: "192.168.1.100", macAddress: "11:22:33:44:55:66", hostname: "My-iPhone", vendor: "Apple"),
        LANDevice(ipAddress: "192.168.1.101", macAddress: "66:77:88:99:00:AA", hostname: "My-MacBook", vendor: "Apple"),
        LANDevice(ipAddress: "192.168.1.150", macAddress: "BB:CC:DD:EE:FF:11", hostname: "Smart-TV", vendor: "Samsung"),
        LANDevice(ipAddress: "192.168.1.200", macAddress: "22:33:44:55:66:77", hostname: "NAS-Server", vendor: "Synology"),
        LANDevice(ipAddress: "192.168.1.201", hostname: "Unknown-Device"),
        LANDevice(ipAddress: "192.168.1.210", macAddress: "CC:DD:EE:FF:11:22", vendor: "Google"),
        LANDevice(ipAddress: "192.168.1.220", macAddress: "DD:EE:FF:11:22:33", hostname: "Smart-Bulb", vendor: "Philips"),
        LANDevice(ipAddress: "192.168.1.230", macAddress: "EE:FF:11:22:33:44", hostname: "Printer", vendor: "HP"),
        LANDevice(ipAddress: "192.168.1.240", macAddress: "FF:11:22:33:44:55", hostname: "Security-Camera", vendor: "Xiaomi")
    ]
}

extension MockLANService: ILANServiceProtocol {
    func startScan() {
        print("MockLANService: Начинаем сканирование LAN")
        
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
            
            progress += 0.01
            self.scanProgress = min(progress, 1.0)
            
            let targetCount = Int(progress * Double(self.mockDevices.count))
            while self.discoveredDevices.count < targetCount && self.discoveredDevices.count < self.mockDevices.count {
                let device = self.mockDevices[self.discoveredDevices.count]
                self.discoveredDevices.append(device)
                print("MockLANService: Найдено устройство \(device.hostname ?? device.ipAddress)")
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                self.isScanning = false
                
                let result = NetworkStatus.ScanResult(
                    deviceCount: self.discoveredDevices.count,
                    duration: 10.0,
                    foundDevices: self.discoveredDevices.count
                )
                
                self.networkStatus = .completed(result)
                print("MockLANService: Сканирование завершено, найдено \(self.discoveredDevices.count) устройств")
            }
        }
    }
    
    func stopScan() {
        print("MockLANService: Останавливаем сканирование")
        
        timer?.invalidate()
        timer = nil
        isScanning = false
        
        let result = NetworkStatus.ScanResult(
            deviceCount: discoveredDevices.count,
            duration: 5.0,
            foundDevices: discoveredDevices.count
        )
        
        networkStatus = .completed(result)
    }
    
    func refreshNetworkInfo() {
        currentSSID = "Test_WiFi_Network"
        print("MockLANService: Обновлена информация о сети, SSID: \(currentSSID ?? "нет")")
    }
}
