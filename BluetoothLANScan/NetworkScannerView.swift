//
//  ScanView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import SwiftUI

struct NetworkScannerView: View {
    @StateObject private var viewModel = NetworkScannerViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ProgressView(value: viewModel.scanProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                    .accentColor(.blue)
                    .opacity(viewModel.isScanning ? 1 : 0)
                
                Text(viewModel.currentStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Picker("Тип устройства", selection: $viewModel.selectedTab) {
                    Text("Bluetooth (\(viewModel.bluetoothDevices.count))").tag(0)
                    Text("LAN (\(viewModel.lanDevices.count))").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Network Scanner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

