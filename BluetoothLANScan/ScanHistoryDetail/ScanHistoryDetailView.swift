//
//  ScanDetailView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI

struct ScanDetailView: View {
    @StateObject private var viewModel: ScanHistoryDetailViewModel
    
    init(scan: ScanHistory) {
        _viewModel = StateObject(wrappedValue: ScanHistoryDetailViewModel(scan: scan))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScanDetailHeaderView(
                timestamp: viewModel.formattedTimestamp,
                duration: viewModel.scanDuration,
                totalDevices: Int(viewModel.scan.totalDevices)
            )
            
            DeviceTypePickerView(
                selectedTab: $viewModel.selectedTab,
                bluetoothCount: Int(viewModel.scan.bluetoothCount),
                lanCount: Int(viewModel.scan.lanCount)
            )
            
            DeviceListContainerView(
                viewModel: viewModel,
                selectedTab: viewModel.selectedTab,
                searchText: viewModel.searchText
            )
            
            Spacer()
        }
        .navigationTitle("Детали сканирования")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Поиск устройств")
        .onAppear {
            viewModel.loadDevices()
        }
    }
}

struct ScanDetailHeaderView: View {
    let timestamp: String
    let duration: String
    let totalDevices: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Сканирование от \(timestamp)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 30) {
                DetailItemView(
                    title: "Длительность",
                    value: duration,
                    icon: "timer"
                )
                
                DetailItemView(
                    title: "Всего устройств",
                    value: "\(totalDevices)",
                    icon: "number"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct DeviceTypePickerView: View {
    @Binding var selectedTab: Int
    let bluetoothCount: Int
    let lanCount: Int
    
    var body: some View {
        Picker("Тип устройств", selection: $selectedTab) {
            Text("Bluetooth (\(bluetoothCount))")
                .tag(0)
            Text("Сеть (\(lanCount))")
                .tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct DeviceListContainerView: View {
    @ObservedObject var viewModel: ScanHistoryDetailViewModel
    let selectedTab: Int
    let searchText: String
    
    var body: some View {
        Group {
            if selectedTab == 0 {
                BluetoothDeviceListView(
                    devices: viewModel.filteredBluetoothDevices,
                    searchText: searchText,
                    viewModel: viewModel
                )
            } else {
                LANDeviceListView(
                    devices: viewModel.filteredLANDevices,
                    searchText: searchText,
                    viewModel: viewModel
                )
            }
        }
    }
}

struct BluetoothDeviceListView: View {
    let devices: [BluetoothDeviceHistory]
    let searchText: String
    @ObservedObject var viewModel: ScanHistoryDetailViewModel
    
    var body: some View {
        Group {
            if devices.isEmpty {
                EmptyDeviceListView(
                    hasSearchQuery: !searchText.isEmpty,
                    deviceType: "Bluetooth",
                    icon: "dot.radiowaves.left.and.right",
                    iconColor: .blue
                )
            } else {
                List(devices) { device in
                    NavigationLink(
                        destination: DeviceDetailView(
                            device: .bluetooth(viewModel.convertToBluetoothDevice(device))
                        )
                    ) {
                        BluetoothDeviceRow(device: device)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct LANDeviceListView: View {
    let devices: [LANDeviceHistory]
    let searchText: String
    @ObservedObject var viewModel: ScanHistoryDetailViewModel
    
    var body: some View {
        Group {
            if devices.isEmpty {
                EmptyDeviceListView(
                    hasSearchQuery: !searchText.isEmpty,
                    deviceType: "сетевых",
                    icon: "network",
                    iconColor: .green
                )
            } else {
                List(devices) { device in
                    NavigationLink(
                        destination: DeviceDetailView(
                            device: .lan(viewModel.convertToLANDevice(device))
                        )
                    ) {
                        LANDeviceRow(device: device)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct EmptyDeviceListView: View {
    let hasSearchQuery: Bool
    let deviceType: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(iconColor.opacity(0.5))
                .padding()
            
            VStack(spacing: 8) {
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding(.top, 50)
    }
    
    private var titleText: String {
        hasSearchQuery ? "Ничего не найдено" : "Устройства не обнаружены"
    }
    
    private var subtitleText: String {
        hasSearchQuery ?
        "Попробуйте изменить запрос" :
        "\(deviceType) устройства не были найдены во время этого сканирования"
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
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ date: Date) -> String {
        DateFormatter.localizedString(
            from: date,
            dateStyle: .none,
            timeStyle: .short
        )
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
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ date: Date) -> String {
        DateFormatter.localizedString(
            from: date,
            dateStyle: .none,
            timeStyle: .short
        )
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
