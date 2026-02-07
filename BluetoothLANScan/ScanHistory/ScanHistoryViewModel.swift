//
//  ScanHistoryViewModel.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import Combine
import SwiftUI
import CoreData

protocol IHistoryViewModel {
    func loadScans()
    func deleteScan(scan: ScanHistory)
}

final class HistoryViewModel: ObservableObject {
    @Published var scans: [ScanHistory] = []
    @Published var searchText = ""
    @Published var selectedTimeFilter = TimeFilter.all
    
    private let dataManager = DataManager.shared
    
    init() {
        loadScans()
    }
    
    private func applyTimeFilter(to scans: [ScanHistory]) -> [ScanHistory] {
        let calendar = Calendar.current
        let now = Date()
        
        return scans.filter { scan in
            guard let timestamp = scan.timestamp else { return false }
            
            switch selectedTimeFilter {
            case .today:
                return calendar.isDateInToday(timestamp)
            case .lastWeek:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                return timestamp >= weekAgo
            case .lastMonth:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
                return timestamp >= monthAgo
            case .all:
                return true
            }
        }
    }
}

extension HistoryViewModel: IHistoryViewModel {
    func loadScans() {
        let allScans = dataManager.fetchAllScans()
        
        var filteredScans = allScans
        if selectedTimeFilter != .all {
            filteredScans = applyTimeFilter(to: filteredScans)
        }
        
        if !searchText.isEmpty {
            filteredScans = filteredScans.filter { scan in
                let bluetoothDevices = dataManager.fetchBluetoothDevices(scan: scan)
                let bluetoothMatch = bluetoothDevices.contains { device in
                    device.name?.lowercased().contains(searchText.lowercased()) ?? false
                }
                
                let lanDevices = dataManager.fetchLANDevices(scan: scan)
                let lanMatch = lanDevices.contains { device in
                    device.hostname?.lowercased().contains(searchText.lowercased()) ?? false ||
                    device.ipAddress?.lowercased().contains(searchText.lowercased()) ?? false
                }
                
                return bluetoothMatch || lanMatch
            }
        }
        
        scans = filteredScans.sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
    }
    
    func deleteScan(scan: ScanHistory) {
        dataManager.deleteScan(scan: scan)
        self.loadScans()
    }
}

enum TimeFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case today = "Сегодня"
    case lastWeek = "За неделю"
    case lastMonth = "За месяц"
    
    var id: String { self.rawValue }
}
