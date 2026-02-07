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
    func deleteAllScans()
}

final class HistoryViewModel: ObservableObject {
    @Published var scans: [ScanHistory] = []
    @Published var statistics = ScanStatistics()
    
    private let dataManager = DataManager.shared
    
    init() {
        loadScans()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHistoryUpdate),
            name: .scanHistoryUpdated,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleHistoryUpdate() {
        DispatchQueue.main.async {
            self.loadScans()
        }
    }
}

extension HistoryViewModel: IHistoryViewModel {
    func loadScans() {
        scans = dataManager.fetchAllScans()
        statistics = dataManager.getStatistics()
    }
    
    func deleteScan(scan: ScanHistory) {
        dataManager.deleteScan(scan: scan)
        loadScans()
    }
    
    func deleteAllScans() {
        dataManager.deleteAllScans()
        loadScans()
    }
}
