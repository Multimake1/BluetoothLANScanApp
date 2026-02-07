//
//  ScanViewModel.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import Foundation
import Combine
import CoreData

protocol IScanViewModel {
    func startScanning()
    func stopScanning()
    func connectToDevice(device: DeviceItem)
    
    var allDevices: [DeviceItem] { get }
    var currentStatusText: String { get }
}

final class ScanViewModel: ObservableObject {
    let bluetoothService: IBluetoothServiceProtocol
    let lanService: ILANServiceProtocol
    private let bluetoothPublishers: BluetoothPublishers
    private let lanPublishers: LANPublishers
    
    @Published var bluetoothDevices: [BluetoothDevice] = []
    @Published var lanDevices: [LANDevice] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var networkStatus: NetworkStatus = .ready
    @Published var selectedTab = 0
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var showScanAnimation = false
    
    private var cancellables = Set<AnyCancellable>()
    private var scanStartTime: Date?
    private let dataManager = DataManager.shared
    
    init(bluetoothService: IBluetoothServiceProtocol,
         lanService: ILANServiceProtocol,
         bluetoothPublishers: BluetoothPublishers,
         lanPublishers: LANPublishers) {
        
        self.bluetoothService = bluetoothService
        self.lanService = lanService
        self.bluetoothPublishers = bluetoothPublishers
        self.lanPublishers = lanPublishers
        
        setupBindings()
    }
    
    private func setupBindings() {
        bluetoothPublishers.discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: \.bluetoothDevices, on: self)
            .store(in: &cancellables)
        
        bluetoothPublishers.isScanning
            .combineLatest(lanPublishers.isScanning)
            .map { $0 || $1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isScanning in
                self?.isScanning = isScanning
                self?.showScanAnimation = isScanning
            }
            .store(in: &cancellables)
        
        bluetoothPublishers.scanProgress
            .combineLatest(lanPublishers.scanProgress)
            .map { (btProgress, lanProgress) in
                return (btProgress * 0.3) + (lanProgress * 0.7)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.scanProgress, on: self)
            .store(in: &cancellables)
        
        lanPublishers.discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: \.lanDevices, on: self)
            .store(in: &cancellables)
        
        bluetoothPublishers.networkStatus
            .combineLatest(lanPublishers.networkStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (btStatus, lanStatus) in
                self?.updateCombinedNetworkStatus(bluetoothStatus: btStatus, lanStatus: lanStatus)
                
                if case .completed(let btResult) = btStatus,
                   case .completed(let lanResult) = lanStatus {
                    
                    let totalDevices = btResult.foundDevices + lanResult.foundDevices
                    let totalDuration = max(btResult.duration, lanResult.duration)
                    
                    let combinedResult = NetworkStatus.ScanResult(
                        deviceCount: btResult.deviceCount + lanResult.deviceCount,
                        duration: totalDuration,
                        foundDevices: totalDevices
                    )
                    
                    self?.saveScanToHistory(result: combinedResult)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateCombinedNetworkStatus(bluetoothStatus: NetworkStatus, lanStatus: NetworkStatus) {
        if bluetoothStatus.hasError {
            networkStatus = bluetoothStatus
        } else if lanStatus.hasError {
            networkStatus = lanStatus
        }
        else if bluetoothStatus.isScanning || lanStatus.isScanning {
            networkStatus = .scanning
        }
        else if !bluetoothService.isScanning && !lanService.isScanning &&
                !bluetoothStatus.hasError && !lanStatus.hasError {
            networkStatus = .ready
        }
    }
    
    private func showScanStatistics() {
        guard let startTime = scanStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let totalDevices = bluetoothDevices.count + lanDevices.count
        
        let durationText: String
        if duration < 60 {
            durationText = "\(Int(duration)) секунд"
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            durationText = "\(minutes) минут \(seconds) секунд"
        }
        
        alertMessage = """
        Результаты сканирования
        
        Длительность: \(durationText)
        
        Найдено устройств: \(totalDevices)
        Bluetooth: \(bluetoothDevices.count)
        Сеть: \(lanDevices.count)
        """
        
        showingAlert = true
        scanStartTime = nil
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func saveScanToHistory(result: NetworkStatus.ScanResult) {
        dataManager.saveScan(
            scanResult: result,
            bluetoothDevices: bluetoothDevices,
            lanDevices: lanDevices
        )
    }
}

extension ScanViewModel: IScanViewModel {
    func startScanning() {
        guard networkStatus.canStartScan else {
            showAlert(message: "Невозможно начать сканирование в текущем состоянии")
            return
        }
        
        scanStartTime = Date()
        
        lanService.refreshNetworkInfo()
        
        bluetoothDevices.removeAll()
        lanDevices.removeAll()
        
        bluetoothService.startScan()
        lanService.startScan()
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        bluetoothService.stopScan()
        lanService.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showScanAnimation = false
        }
        
        showScanStatistics()
    }
    
    func connectToDevice(device: DeviceItem) {
        switch device {
        case .bluetooth(let bluetoothDevice):
            bluetoothService.connectToDevice(device: bluetoothDevice)
        case .lan:
            break
        }
    }
    
    var allDevices: [DeviceItem] {
        let bluetoothItems = bluetoothDevices.map { DeviceItem.bluetooth($0) }
        let lanItems = lanDevices.map { DeviceItem.lan($0) }
        return bluetoothItems + lanItems
    }
    
    var currentStatusText: String {
        return networkStatus.displayText
    }
}
