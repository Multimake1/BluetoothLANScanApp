//
//  ScanDetailView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI

struct ScanDetailView: View {
    let scan: ScanHistory
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var bluetoothDevices: [BluetoothDeviceHistory] = []
    @State private var lanDevices: [LANDeviceHistory] = []
    
    private let dataManager = DataManager.shared
    
    var filteredBluetoothDevices: [BluetoothDeviceHistory] {
        if searchText.isEmpty {
            return bluetoothDevices
        } else {
            return bluetoothDevices.filter { device in
                device.name?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }
    
    var filteredLANDevices: [LANDeviceHistory] {
        if searchText.isEmpty {
            return lanDevices
        } else {
            return lanDevices.filter { device in
                device.hostname?.lowercased().contains(searchText.lowercased()) ?? false ||
                device.ipAddress?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Сканирование от \(formatDate(scan.timestamp ?? Date()))")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    DetailItemView(
                        title: "Длительность",
                        value: String(format: "%.1fс", scan.duration),
                        icon: "timer"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    DetailItemView(
                        title: "Всего устройств",
                        value: "\(scan.totalDevices)",
                        icon: "number"
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                
                TextField("Поиск устройств...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 10)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 12)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 12)
            
            Picker("Тип устройств", selection: $selectedTab) {
                Text("Bluetooth (\(filteredBluetoothDevices.count))")
                    .tag(0)
                Text("Сеть (\(filteredLANDevices.count))")
                    .tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            DeviceHistoryDetailListView(
                selectedTab: selectedTab,
                bluetoothDevices: filteredBluetoothDevices,
                lanDevices: filteredLANDevices,
                searchText: searchText
            )
            
            Spacer()
        }
        .navigationTitle("Детали сканирования")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDevices()
        }
    }
    
    private func loadDevices() {
        bluetoothDevices = dataManager.fetchBluetoothDevices(scan: scan)
        lanDevices = dataManager.fetchLANDevices(scan: scan)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DeviceHistoryDetailListView: View {
    let selectedTab: Int
    let bluetoothDevices: [BluetoothDeviceHistory]
    let lanDevices: [LANDeviceHistory]
    let searchText: String
    
    var body: some View {
        Group {
            if selectedTab == 0 {
                if bluetoothDevices.isEmpty {
                    EmptyDeviceView(
                        hasSearchQuery: !searchText.isEmpty,
                        deviceType: "Bluetooth"
                    )
                } else {
                    List(bluetoothDevices) { device in
                        BluetoothDeviceRow(device: device)
                    }
                }
            } else {
                if lanDevices.isEmpty {
                    EmptyDeviceView(
                        hasSearchQuery: !searchText.isEmpty,
                        deviceType: "сетевых"
                    )
                } else {
                    List(lanDevices) { device in
                        LANDeviceRow(device: device)
                    }
                }
            }
        }
    }
}

struct EmptyDeviceView: View {
    let hasSearchQuery: Bool
    let deviceType: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(hasSearchQuery ?
                 "\(deviceType) устройства по запросу не найдены" :
                 "\(deviceType) устройства не найдены")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct DetailItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BluetoothDeviceRow: View {
    let device: BluetoothDeviceHistory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? "Неизвестное устройство")
                    .font(.headline)
                
                HStack {
                    Text("RSSI: \(device.rssi) dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(device.timestamp ?? Date()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LANDeviceRow: View {
    let device: LANDeviceHistory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "network")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.hostname ?? device.ipAddress ?? "Неизвестное устройство")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let ip = device.ipAddress {
                        Text("IP: \(ip)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let mac = device.macAddress {
                        Text("MAC: \(mac)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(formatTime(device.timestamp ?? Date()))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
