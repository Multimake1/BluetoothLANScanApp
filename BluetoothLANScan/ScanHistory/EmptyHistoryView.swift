//
//  EmptyHistoryView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI

struct EmptyHistoryView: View {
    let searchText: String
    let timeFilter: TimeFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            if !searchText.isEmpty || timeFilter != .all {
                VStack(spacing: 8) {
                    Text("Ничего не найдено")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Text("По запросу \"\(searchText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if timeFilter != .all {
                        Text("за период: \(timeFilter.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 8) {
                    Text("История сканирований пуста")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Выполните сканирование, чтобы увидеть здесь результаты")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}
