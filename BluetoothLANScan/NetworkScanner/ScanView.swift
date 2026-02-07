//
//  ScanView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import SwiftUI
import Combine

struct NetworkScannerView: View {
    @StateObject private var viewModel: ScanViewModel
    @EnvironmentObject var appState: AppState
    //@State private var showingDebugInfo = false
    
    init() {
        let factory = NetworkServicesFactory.shared
        //factory.mode = .mock
        
        _viewModel = StateObject(wrappedValue: factory.createScanViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                /*if showingDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Отладочная информация:")
                            .font(.caption)
                            .bold()
                        
                        Text("Режим: \(appState.useMockServices ? "Тестовый" : "Реальный")")
                            .font(.caption2)
                        
                        Text("Bluetooth устройств: \(viewModel.bluetoothDevices.count)")
                            .font(.caption2)
                        
                        Text("LAN устройств: \(viewModel.lanDevices.count)")
                            .font(.caption2)
                        
                        Text("Прогресс: \(Int(viewModel.scanProgress * 100))%")
                            .font(.caption2)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }*/
                
                StatusPanelView(networkStatus: viewModel.networkStatus)
                    .padding(.horizontal)
                
                if viewModel.isScanning {
                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.scanProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(viewModel.networkStatus.color.swiftUIColor)
                        
                        Text("\(Int(viewModel.scanProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                ScanButton(
                    isScanning: viewModel.isScanning,
                    canStart: viewModel.networkStatus.canStartScan,
                    hasError: viewModel.networkStatus.hasError,
                    action: {
                        if viewModel.isScanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    }
                )
                .padding(.horizontal)
                .disabled(!viewModel.networkStatus.canStartScan && !viewModel.isScanning)
                
                Picker("Тип устройств", selection: $viewModel.selectedTab) {
                    Text("Bluetooth (\(viewModel.bluetoothDevices.count))")
                        .tag(0)
                    Text("LAN (\(viewModel.lanDevices.count))")
                        .tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                DeviceListView(
                    devices: viewModel.selectedTab == 0 ?
                        viewModel.bluetoothDevices.map { DeviceItem.bluetooth($0) } :
                        viewModel.lanDevices.map { DeviceItem.lan($0) },
                    networkStatus: viewModel.networkStatus
                )
            }
            .navigationTitle("Сканер сети")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                /*ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDebugInfo.toggle()
                    } label: {
                        Image(systemName: showingDebugInfo ? "info.circle.fill" : "info.circle")
                    }
                }*/
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Очистить") {
                        viewModel.bluetoothDevices.removeAll()
                        viewModel.lanDevices.removeAll()
                    }
                    .disabled(viewModel.isScanning)
                }
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text("Информация"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                (viewModel.lanService as? ILANServiceProtocol)?.refreshNetworkInfo()
            }
            .onChange(of: appState.useMockServices) { newValue in
                let factory = NetworkServicesFactory.shared
                factory.mode = newValue ? .mock : .real
                
                DispatchQueue.main.async {
                    viewModel.objectWillChange.send()
                }
            }
        }
    }
}

struct StatusPanelView: View {
    let networkStatus: NetworkStatus
    
    var body: some View {
        HStack {
            Image(systemName: networkStatus.icon)
                .font(.title2)
                .foregroundColor(networkStatus.color.swiftUIColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(networkStatus.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if case .completed(let result) = networkStatus {
                    Text(result.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(networkStatus.color.swiftUIColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(networkStatus.color.swiftUIColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ScanButton: View {
    let isScanning: Bool
    let canStart: Bool
    let hasError: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        if isScanning {
            return .red
        } else if hasError {
            return .orange
        } else if canStart {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var buttonText: String {
        if isScanning {
            return "Остановить сканирование"
        } else if hasError {
            return "Повторить сканирование"
        } else {
            return "Начать сканирование"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isScanning ? "stop.circle.fill" :
                                 hasError ? "exclamationmark.arrow.circlepath" :
                                 "play.circle.fill")
                Text(buttonText)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonColor)
            .cornerRadius(10)
        }
    }
}

struct DeviceListView: View {
    let devices: [DeviceItem]
    let networkStatus: NetworkStatus
    
    var body: some View {
        Group {
            if devices.isEmpty {
                EmptyStateView(networkStatus: networkStatus)
            } else {
                List(devices) { device in
                    DeviceRow(device: device)
                        .listRowSeparator(.visible)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct DeviceRow: View {
    let device: DeviceItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: deviceIconName)
                .font(.title3)
                .foregroundColor(deviceIconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(device.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var deviceIconName: String {
        switch device {
        case .bluetooth:
            return "antenna.radiowaves.left.and.right"
        case .lan:
            return "network"
        }
    }
    
    private var deviceIconColor: Color {
        switch device {
        case .bluetooth:
            return .blue
        case .lan:
            return .green
        }
    }
}

struct EmptyStateView: View {
    let networkStatus: NetworkStatus
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: networkStatus.isScanning ? "magnifyingglass" : "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(networkStatus.color.swiftUIColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptyStateDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        if networkStatus.isScanning {
            return "Идет поиск устройств..."
        } else if networkStatus.hasError {
            return "Ошибка сканирования"
        } else {
            return "Устройства не найдены"
        }
    }
    
    private var emptyStateDescription: String {
        if networkStatus.isScanning {
            return "Пожалуйста, подождите, идет сканирование сети и Bluetooth устройств"
        } else if networkStatus.hasError {
            if case .error(let networkError) = networkStatus {
                return networkError.description
            }
            return "Произошла ошибка при сканировании"
        } else {
            return "Нажмите 'Начать сканирование' для поиска устройств в сети и по Bluetooth"
        }
    }
}
#Preview {
    NetworkScannerView()
}

#Preview("Ошибка Bluetooth") {
    struct PreviewView: View {
        @StateObject private var viewModel: ScanViewModel
        
        init() {
            let factory = NetworkServicesFactory.shared
            let vm = factory.createScanViewModel()
            vm.networkStatus = .error(.bluetoothDisabled)
            _viewModel = StateObject(wrappedValue: vm)
        }
        
        var body: some View {
            NetworkScannerView()
        }
    }
    return PreviewView()
}

