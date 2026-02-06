//
//  LANService.swift
//  BluetoothLANScan
//
//  Created by Арсений on 05.02.2026.
//

import Foundation
import Combine
import Network
import LanScanner

protocol ILANServiceProtocol: AnyObject {
    var discoveredDevices: [LANDevice] { get }
    var isScanning: Bool { get }
    var scanProgress: Double { get }
    var networkStatus: NetworkStatus { get }
    var currentSSID: String? { get }
    
    func startScan()
    func stopScan()
    func refreshNetworkInfo()
}

final class LANService: NSObject {
    @Published private(set) var discoveredDevices: [LANDevice] = []     // Найденные устройства
    @Published private(set) var isScanning = false                      // Состояние сканера
    @Published private(set) var scanProgress: Double = 0.0              // Прогресс
    @Published private(set) var networkStatus: NetworkStatus = .ready   // Статус сканирования
    @Published private(set) var currentSSID: String?                    // Название сети
    
    private var scanner: LanScanner?                    // Экземпляр сканера из библиотеки
    private var totalIPsToScan = 254                    // Всего IP для сканирования (/24 подсеть)
    private var scannedIPs = 0                          // Уже сканированные IP
    private var timer: Timer?                           // Таймер для контроля времени
    private var scanStartTime: Date?                    // Время начала сканирования
    private var deviceCache: [String: LanDevice] = [:]  // Кэш устройств по ключу "IP-MAC"
    private var expectedDeviceCount = 0
    
    override init() {
        super.init()
        refreshNetworkInfo()
    }
    
    deinit {
        stopScan()
    }
    
    private func resetScanState() {
        discoveredDevices.removeAll()
        deviceCache.removeAll()
        scannedIPs = 0
        scanProgress = 0.0
        expectedDeviceCount = totalIPsToScan
    }
    
    private func validateWiFiConnection() -> Bool {
        if currentSSID == nil {
            networkStatus = .error(.wifiNotConnected)
            return false
        }
        return true
    }
    
    // Таймер на 15 секунд для автоматической остановки
    private func startSafetyTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleScanTimeout()
            }
        }
    }
    
    private func handleScanTimeout() {
        let duration = scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let result = NetworkStatus.ScanResult(
            deviceCount: expectedDeviceCount,
            duration: duration,
            foundDevices: discoveredDevices.count
        )
        
        networkStatus = .error(.timeout)
        isScanning = false
        scanner?.stop()
        scanner = nil
        
        NotificationCenter.default.post(
            name: Notification.Name("LANScanTimeout"),
            object: nil,
            userInfo: ["result": result]
        )
    }
    
    private func updateProgress() {
        guard totalIPsToScan > 0 else {
            scanProgress = 0.0
            return
        }
        
        scanProgress = min(Double(scannedIPs) / Double(totalIPsToScan), 1.0)
    }
    
    private func processDevice(_ device: LanDevice) {
        let lanDevice = LANDevice(
            id: UUID(),
            ipAddress: device.ipAddress,
            macAddress: device.mac.isEmpty ? nil : device.mac,
            hostname: device.name.isEmpty ? nil : device.name,
            vendor: device.brand.isEmpty ? nil : device.brand,
            lastSeen: Date()
        )
        
        let deviceKey = "\(device.ipAddress)-\(device.mac)"
        
        if deviceCache[deviceKey] == nil {
            deviceCache[deviceKey] = device
            discoveredDevices.append(lanDevice)
            
            print("Найдено устройство: \(device.name.isEmpty ? device.ipAddress : device.name)")
        } else {
            if let index = discoveredDevices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
                discoveredDevices[index] = lanDevice
            }
        }
    }
    
    private func printResultStatistics(result: NetworkStatus.ScanResult) {
        print("Результаты сканирования:")
        print("Найдено устройств: \(result.foundDevices)")
        print("Просканировано IP: \(result.deviceCount)")
        print("Длительность: \(String(format: "%.1f", result.duration))с")
    }
    
    private func checkNetworkPermissions() -> Bool {
        refreshNetworkInfo()
        
        guard let ssid = currentSSID, !ssid.isEmpty else {
            networkStatus = .error(.wifiNotConnected)
            return false
        }
        
        return true
    }
}

extension LANService: LanScannerDelegate {
    func lanScanHasUpdatedProgress(_ progress: CGFloat, address: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.scanProgress = Double(progress)
            self.scannedIPs = Int(progress * CGFloat(self.totalIPsToScan))
            
            if Int(progress * 100) % 5 == 0 {
                print("Прогресс: \(Int(progress * 100))%")
            }
        }
    }
    
    func lanScanDidFindNewDevice(_ device: LanDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.processDevice(device)
        }
    }
    
    func lanScanDidFinishScanning() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timer?.invalidate()
            self.timer = nil
            
            let duration = self.scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
            let result = NetworkStatus.ScanResult(
                deviceCount: self.totalIPsToScan,
                duration: duration,
                foundDevices: self.discoveredDevices.count
            )
            
            self.isScanning = false
            self.scanProgress = 1.0
            self.networkStatus = .completed(result)
            
            self.printResultStatistics(result: result)
            
            NotificationCenter.default.post(
                name: Notification.Name("LANScanCompleted"),
                object: nil,
                userInfo: ["result": result]
            )
        }
    }
}

extension LANService: ILANServiceProtocol {
    func startScan() {
        guard networkStatus.canStartScan else {
            return
        }
        
        resetScanState()
        refreshNetworkInfo()
        
        guard validateWiFiConnection() else {
            networkStatus = .error(.wifiNotConnected)
            return
        }
        
        networkStatus = .preparing
        isScanning = true
        scanStartTime = Date()
        scanner = LanScanner(delegate: self)
        startSafetyTimer()
        scanner?.start()
        networkStatus = .scanning
    }
        
    func stopScan() {
        guard isScanning else { return }
        
        scanner?.stop()
        scanner = nil
        timer?.invalidate()
        timer = nil
        
        isScanning = false
        
        let duration = scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let result = NetworkStatus.ScanResult(
            deviceCount: expectedDeviceCount,
            duration: duration,
            foundDevices: discoveredDevices.count
        )
        
        networkStatus = .completed(result)
        printResultStatistics(result: result)
    }
        
    func refreshNetworkInfo() {
        currentSSID = scanner?.getCurrentWifiSSID()
        
        if currentSSID != nil {
            if case .error(.wifiNotConnected) = networkStatus {
                networkStatus = .ready
            }
        }
    }
}

extension LANService {
    func sortDevices(by criteria: DeviceSortCriteria) {
        switch criteria {
        case .ipAddress:
            discoveredDevices.sort { $0.ipAddress.compare($1.ipAddress, options: .numeric) == .orderedAscending }
        case .name:
            discoveredDevices.sort {
                let name1 = $0.hostname ?? $0.ipAddress
                let name2 = $1.hostname ?? $1.ipAddress
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        case .lastSeen:
            discoveredDevices.sort { $0.lastSeen > $1.lastSeen }
        }
    }
}

enum DeviceSortCriteria {
    case ipAddress
    case name
    case lastSeen
}

