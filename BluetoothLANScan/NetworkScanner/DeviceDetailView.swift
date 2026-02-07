//
//  ScanDetailView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI

struct DeviceDetailView: View {
    let device: DeviceItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: deviceIcon)
                        .font(.system(size: 50))
                        .foregroundColor(deviceColor)
                    
                    Text(device.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(device.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                SectionView(title: "Общая информация") {
                    InfoRow(title: "Тип", value: deviceTypeText)
                    InfoRow(title: "Статус", value: statusText)
                    InfoRow(title: "Последний раз видели", value: lastSeenText)
                }
                
                switch device {
                case .bluetooth(let bluetoothDevice):
                    BluetoothDetailsView(device: bluetoothDevice)
                case .lan(let lanDevice):
                    LANDetailsView(device: lanDevice)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Детали устройства")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var deviceIcon: String {
        switch device {
        case .bluetooth:
            return "dot.radiowaves.left.and.right"
        case .lan:
            return "network"
        }
    }
    
    private var deviceColor: Color {
        switch device {
        case .bluetooth:
            return .blue
        case .lan:
            return .green
        }
    }
    
    private var deviceTypeText: String {
        switch device.type {
        case .bluetooth:
            return "Bluetooth устройство"
        case .lan:
            return "Сетевое устройство"
        }
    }
    
    private var statusText: String {
        switch device {
        case .bluetooth(let bluetoothDevice):
            return bluetoothDevice.status.rawValue
        case .lan:
            return "Обнаружено"
        }
    }
    
    private var lastSeenText: String {
        let date: Date
        switch device {
        case .bluetooth(let bluetoothDevice):
            date = bluetoothDevice.lastSeen
        case .lan(let lanDevice):
            date = lanDevice.lastSeen
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BluetoothDetailsView: View {
    let device: BluetoothDevice
    
    var body: some View {
        SectionView(title: "Bluetooth информация") {
            InfoRow(title: "Имя устройства", value: device.name ?? "Неизвестно")
            InfoRow(title: "Сила сигнала", value: "\(device.rssi) dB")
            InfoRow(title: "ID устройства", value: device.id.uuidString)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Качество сигнала")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < signalStrength ? "wifi" : "wifi.slash")
                            .foregroundColor(signalColor)
                    }
                    
                    Spacer()
                    
                    Text(signalDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var signalStrength: Int {
        if device.rssi >= -50 { return 5 }
        else if device.rssi >= -60 { return 4 }
        else if device.rssi >= -70 { return 3 }
        else if device.rssi >= -80 { return 2 }
        else { return 1 }
    }
    
    private var signalColor: Color {
        if device.rssi >= -60 { return .green }
        else if device.rssi >= -70 { return .yellow }
        else if device.rssi >= -80 { return .orange }
        else { return .red }
    }
    
    private var signalDescription: String {
        if device.rssi >= -50 { return "Отличный" }
        else if device.rssi >= -60 { return "Хороший" }
        else if device.rssi >= -70 { return "Средний" }
        else if device.rssi >= -80 { return "Слабый" }
        else { return "Очень слабый" }
    }
}

struct LANDetailsView: View {
    let device: LANDevice
    
    var body: some View {
        SectionView(title: "Сетевая информация") {
            InfoRow(title: "IP адрес", value: device.ipAddress)
            
            if let mac = device.macAddress {
                InfoRow(title: "MAC адрес", value: mac)
            }
            
            if let hostname = device.hostname {
                InfoRow(title: "Имя хоста", value: hostname)
            }
            
            if let vendor = device.vendor {
                InfoRow(title: "Производитель", value: vendor)
            }
            
            InfoRow(title: "ID устройства", value: device.id.uuidString)
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
