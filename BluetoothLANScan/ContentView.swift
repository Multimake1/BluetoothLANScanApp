//
//  ContentView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 04.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NetworkScannerView()
                .tabItem {
                    Label("Scan", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    ContentView()
}
