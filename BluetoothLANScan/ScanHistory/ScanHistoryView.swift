//
//  ScanHistoryView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import Combine
import SwiftUI
import CoreData

struct ScanHistoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                StatisticsView(statistics: viewModel.statistics)
                    .padding(.horizontal)
                
                if viewModel.scans.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(viewModel.scans) { scan in
                            NavigationLink(destination: ScanDetailView(scan: scan)) {
                                ScanRowView(scan: scan)
                            }
                        }
                        .onDelete(perform: deleteScan)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("История сканирований")
            .toolbar {
                if !viewModel.scans.isEmpty {
                    EditButton()
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func deleteScan(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                let scan = viewModel.scans[index]
                viewModel.deleteScan(scan: scan)
            }
        }
    }
}

struct StatisticsView: View {
    let statistics: ScanStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatisticItemView(
                    title: "Всего сканирований",
                    value: "\(statistics.totalScans)",
                    icon: "magnifyingglass",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 50)
                
                StatisticItemView(
                    title: "Всего устройств",
                    value: "\(statistics.totalDevices)",
                    icon: "antenna.radiowaves.left.and.right",
                    color: .green
                )
            }
            
            HStack {
                StatisticItemView(
                    title: "Bluetooth",
                    value: "\(statistics.totalBluetoothDevices)",
                    icon: "dot.radiowaves.left.and.right",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 50)
                
                StatisticItemView(
                    title: "Сеть",
                    value: "\(statistics.totalLANDevices)",
                    icon: "network",
                    color: .green
                )
            }
            
            if let lastScanDate = statistics.lastScanDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text("Последнее сканирование:")
                        .font(.caption)
                    Spacer()
                    Text(lastScanDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct StatisticItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScanRowView: View {
    let scan: ScanHistory
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                if let timestamp = scan.timestamp {
                    Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 16) {
                    Label("\(scan.bluetoothCount)", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Label("\(scan.lanCount)", systemImage: "network")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label(String(format: "%.0fs", scan.duration), systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack {
                Text("\(scan.totalDevices)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("устр.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ScanDetailView: View {
    let scan: ScanHistory
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            VStack(spacing: 8) {
                if let timestamp = scan.timestamp {
                    Text("Сканирование от \(timestamp.formatted(date: .long, time: .shortened))")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                
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
            
            Picker("Тип устройств", selection: $selectedTab) {
                Text("Bluetooth (\(scan.bluetoothCount))")
                    .tag(0)
                Text("Сеть (\(scan.lanCount))")
                    .tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            DeviceHistoryListView(scan: scan, selectedTab: selectedTab)
            
            Spacer()
        }
        .navigationTitle("Детали сканирования")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeviceHistoryListView: View {
    let scan: ScanHistory
    let selectedTab: Int
    @State private var bluetoothDevices: [BluetoothDeviceHistory] = []
    @State private var lanDevices: [LANDeviceHistory] = []
    
    private let dataManager = DataManager.shared
    
    var body: some View {
        Group {
            if selectedTab == 0 {
                if bluetoothDevices.isEmpty {
                    Text("Bluetooth устройства не найдены")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(bluetoothDevices) { device in
                        BluetoothDeviceRow(device: device)
                    }
                }
            } else {
                if lanDevices.isEmpty {
                    Text("Сетевые устройства не найдены")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(lanDevices) { device in
                        LANDeviceRow(device: device)
                    }
                }
            }
        }
        .onAppear {
            loadDevices()
        }
        .onChange(of: selectedTab) { _ in
            loadDevices()
        }
    }
    
    private func loadDevices() {
        if selectedTab == 0 {
            bluetoothDevices = dataManager.fetchBluetoothDevices(scan: scan)
        } else {
            lanDevices = dataManager.fetchLANDevices(scan: scan)
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
                    
                    if let timestamp = device.timestamp {
                        Spacer()
                        Text(timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
                Text((device.hostname ?? device.ipAddress) ?? "")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("IP: \(device.ipAddress ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let mac = device.macAddress {
                        Text("MAC: \(mac)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let vendor = device.vendor {
                        Text("Производитель: \(vendor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let timestamp = device.timestamp {
                Text(timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
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

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("История сканирований пуста")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Выполните сканирование сети, чтобы увидеть здесь результаты")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
