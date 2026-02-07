//
//  ContentView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            TabView {
                NetworkScannerView()
                    .tabItem {
                        Label("Сканирование", systemImage: "magnifyingglass")
                    }
                
                ScanHistoryView()
                    .tabItem {
                        Label("История", systemImage: "clock")
                    }
            }
            .alert(
                "Разрешения",
                isPresented: $appState.showNetworkPermissionAlert
            ) {
                Button("OK") {
                    self.appState.isNetworkAuthorized = true
                }
            } message: {
                Text("Для работы сканера требуется доступ к локальной сети. Пожалуйста, предоставьте разрешение в настройках.")
            }
            
            if showLaunchScreen {
                LaunchScreenView(isPresented: $showLaunchScreen)
                    .transition(.opacity)
                    .zIndex(1)
            }
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
