//
//  NetworkServicesFactory.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import Foundation
import Combine
import CoreBluetooth
import LanScanner

protocol INetworkServicesFactory {
    func createBluetoothService() -> (service: IBluetoothServiceProtocol, publishers: BluetoothPublishers)
    func createLANService() -> (service: ILANServiceProtocol, publishers: LANPublishers)
    func createScanViewModel() -> ScanViewModel
}

enum ServiceMode {
    case real
    case mock
}

final class NetworkServicesFactory {
    static let shared = NetworkServicesFactory()
    
    var mode: ServiceMode = .mock
    
    private init() {
        
    }
}

extension NetworkServicesFactory: INetworkServicesFactory {
    func createBluetoothService() -> (service: IBluetoothServiceProtocol, publishers: BluetoothPublishers) {
        switch mode {
        case .real:
            let service = BluetoothService()
            let publishers = BluetoothPublishers(
                discoveredDevices: service.$discoveredDevices.eraseToAnyPublisher(),
                isScanning: service.$isScanning.eraseToAnyPublisher(),
                scanProgress: service.$scanProgress.eraseToAnyPublisher(),
                networkStatus: service.$networkStatus.eraseToAnyPublisher()
            )
            return (service, publishers)
            
        case .mock:
            let service = MockBluetoothService()
            let publishers = BluetoothPublishers(
                discoveredDevices: service.$discoveredDevices.eraseToAnyPublisher(),
                isScanning: service.$isScanning.eraseToAnyPublisher(),
                scanProgress: service.$scanProgress.eraseToAnyPublisher(),
                networkStatus: service.$networkStatus.eraseToAnyPublisher()
            )
            return (service, publishers)
        }
    }
    
    func createLANService() -> (service: ILANServiceProtocol, publishers: LANPublishers) {
        switch mode {
        case .real:
            let service = LANService()
            let publishers = LANPublishers(
                discoveredDevices: service.$discoveredDevices.eraseToAnyPublisher(),
                isScanning: service.$isScanning.eraseToAnyPublisher(),
                scanProgress: service.$scanProgress.eraseToAnyPublisher(),
                networkStatus: service.$networkStatus.eraseToAnyPublisher()
            )
            return (service, publishers)
            
        case .mock:
            let service = MockLANService()
            let publishers = LANPublishers(
                discoveredDevices: service.$discoveredDevices.eraseToAnyPublisher(),
                isScanning: service.$isScanning.eraseToAnyPublisher(),
                scanProgress: service.$scanProgress.eraseToAnyPublisher(),
                networkStatus: service.$networkStatus.eraseToAnyPublisher()
            )
            return (service, publishers)
        }
    }
    
    func createScanViewModel() -> ScanViewModel {
        let bluetooth = createBluetoothService()
        let lan = createLANService()
        
        return ScanViewModel(
            bluetoothService: bluetooth.service,
            lanService: lan.service,
            bluetoothPublishers: bluetooth.publishers,
            lanPublishers: lan.publishers
        )
    }
}

struct BluetoothPublishers {
    let discoveredDevices: AnyPublisher<[BluetoothDevice], Never>
    let isScanning: AnyPublisher<Bool, Never>
    let scanProgress: AnyPublisher<Double, Never>
    let networkStatus: AnyPublisher<NetworkStatus, Never>
}

struct LANPublishers {
    let discoveredDevices: AnyPublisher<[LANDevice], Never>
    let isScanning: AnyPublisher<Bool, Never>
    let scanProgress: AnyPublisher<Double, Never>
    let networkStatus: AnyPublisher<NetworkStatus, Never>
}
