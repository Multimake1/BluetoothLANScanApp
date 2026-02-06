//
//  TestView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import SwiftUI

struct TestView: View {
    @State private var isTesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Тестирование мок-сервисов")
                .font(.title)
                .padding()
            
            Button("Тест Bluetooth сканирования") {
                testBluetoothScan()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Тест LAN сканирования") {
                testLANScan()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Тест обоих сервисов") {
                testBothServices()
            }
            .buttonStyle(.borderedProminent)
            
            if isTesting {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
        }
        .padding()
    }
    
    func testBluetoothScan() {
        isTesting = true
        
        let factory = NetworkServicesFactory.shared
        factory.mode = .mock
        
        let bluetooth = factory.createBluetoothService()
        
        print("=== ТЕСТ Bluetooth сканирования ===")
        
        bluetooth.service.startScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Bluetooth устройств найдено: \(bluetooth.service.discoveredDevices.count)")
            
            if let firstDevice = bluetooth.service.discoveredDevices.first {
                print("Первое устройство: \(firstDevice.name ?? "Unknown")")
                bluetooth.service.connectToDevice(device: firstDevice)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                bluetooth.service.stopScan()
                isTesting = false
                print("=== ТЕСТ завершен ===")
            }
        }
    }
    
    func testLANScan() {
        isTesting = true
        
        let factory = NetworkServicesFactory.shared
        factory.mode = .mock
        
        let lan = factory.createLANService()
        
        print("=== ТЕСТ LAN сканирования ===")
        
        lan.service.startScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("LAN устройств найдено: \(lan.service.discoveredDevices.count)")
            
            if let firstDevice = lan.service.discoveredDevices.first {
                print("Первое устройство: \(firstDevice.hostname ?? firstDevice.ipAddress)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                lan.service.stopScan()
                isTesting = false
                print("=== ТЕСТ завершен ===")
            }
        }
    }
    
    func testBothServices() {
        isTesting = true
        
        let factory = NetworkServicesFactory.shared
        factory.mode = .mock
        
        let viewModel = factory.createScanViewModel()
        
        print("=== ТЕСТ обоих сервисов ===")
        
        viewModel.startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("Bluetooth устройств: \(viewModel.bluetoothDevices.count)")
            print("LAN устройств: \(viewModel.lanDevices.count)")
            print("Всего устройств: \(viewModel.allDevices.count)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                viewModel.stopScanning()
                isTesting = false
                print("=== ТЕСТ завершен ===")
            }
        }
    }
}

#Preview {
    TestView()
}
