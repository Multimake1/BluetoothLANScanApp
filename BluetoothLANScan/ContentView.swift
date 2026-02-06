//
//  ContentView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            NetworkScannerView()
                .tabItem {
                    Label("Сканирование", systemImage: "magnifyingglass")
                }
            
            ScanHistoryView()
                .tabItem {
                    Label("История", systemImage: "clock")
                }
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
        .alert(
            "Разрешения",
            isPresented: $appState.showNetworkPermissionAlert
        ) {
            Button("OK") {
            }
        } message: {
            Text("Для работы сканера требуется доступ к локальной сети. Пожалуйста, предоставьте разрешение в настройках.")
        }
    }
}

struct ScanHistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                if let lastScan = appState.lastScanDate {
                    Text("Последнее сканирование: \(lastScan.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Всего найдено устройств: \(appState.totalDevicesFound)")
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("История")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section("Режим работы") {
                    Toggle("Использовать тестовые данные", isOn: $appState.useMockServices)
                        .onChange(of: appState.useMockServices) { newValue in
                            print("Переключен режим: \(newValue ? "Тестовый" : "Реальный")")
                            NetworkServicesFactory.shared.mode = newValue ? .mock : .real
                        }
                }
                
                Section("Статус") {
                    StatusInfoRow()
                }
                
                Section("Информация") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Режим")
                        Spacer()
                        Text(appState.useMockServices ? "Тестовый" : "Реальный")
                            .foregroundColor(appState.useMockServices ? .orange : .green)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.isBluetoothAuthorized = true
        appState.isNetworkAuthorized = true
        
        return ContentView()
            .environmentObject(appState)
    }
}

struct StatusInfoRow: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: appState.useMockServices ? "testtube.2" : "antenna.radiowaves.left.and.right")
                .foregroundColor(appState.useMockServices ? .orange : .blue)
            Text(appState.useMockServices ? "Тестовый режим активен" : "Реальный режим")
            Spacer()
        }
    }
}
