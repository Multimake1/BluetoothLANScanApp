//
//  DataManager.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import Foundation
import CoreData
import Combine

protocol IDataManager {
    func saveScan(scanResult: NetworkStatus.ScanResult,
                  bluetoothDevices: [BluetoothDevice],
                  lanDevices: [LANDevice])
    func fetchAllScans() -> [ScanHistory]
    func fetchScan(id: UUID) -> ScanHistory?
    func fetchBluetoothDevices(scan: ScanHistory) -> [BluetoothDeviceHistory]
    func fetchLANDevices(scan: ScanHistory) -> [LANDeviceHistory]
    func deleteScan(scan: ScanHistory)
    func deleteAllScans()
    func getStatistics() -> ScanStatistics
}

final class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NetworkScannerModel")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Не удалось загрузить хранилище Core Data: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    private func saveContext(_ context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? viewContext
        
        guard contextToSave.hasChanges else { return }
        
        do {
            try contextToSave.save()
        } catch {
            let nsError = error as NSError
            print("Ошибка сохранения CoreData: \(nsError), \(nsError.userInfo)")
        }
    }
}

extension DataManager: IDataManager {
    func saveScan(scanResult: NetworkStatus.ScanResult,
                  bluetoothDevices: [BluetoothDevice],
                  lanDevices: [LANDevice]) {
        
        let backgroundContext = self.backgroundContext
        
        backgroundContext.perform {
            let scanHistory = ScanHistory(context: backgroundContext)
            scanHistory.id = UUID()
            scanHistory.timestamp = Date()
            scanHistory.duration = scanResult.duration
            scanHistory.totalDevices = Int32(scanResult.foundDevices)
            scanHistory.bluetoothCount = Int32(bluetoothDevices.count)
            scanHistory.lanCount = Int32(lanDevices.count)
            
            for device in bluetoothDevices {
                let bluetoothHistory = BluetoothDeviceHistory(context: backgroundContext)
                bluetoothHistory.id = device.id
                bluetoothHistory.name = device.name
                bluetoothHistory.macAddress = nil
                bluetoothHistory.rssi = Int32(device.rssi)
                bluetoothHistory.timestamp = device.lastSeen
                bluetoothHistory.scan = scanHistory
            }
            
            for device in lanDevices {
                let lanHistory = LANDeviceHistory(context: backgroundContext)
                lanHistory.id = device.id
                lanHistory.ipAddress = device.ipAddress
                lanHistory.macAddress = device.macAddress
                lanHistory.hostname = device.hostname
                lanHistory.vendor = device.vendor
                lanHistory.timestamp = device.lastSeen
                lanHistory.scan = scanHistory
            }
            
            do {
                try backgroundContext.save()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .scanHistoryUpdated, object: nil)
                }
            } catch {
                print("Ошибка сохранения сканирования: \(error)")
            }
        }
    }
    
    func fetchAllScans() -> [ScanHistory] {
        let fetchRequest: NSFetchRequest<ScanHistory> = ScanHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Ошибка загрузки истории сканирований: \(error)")
            return []
        }
    }
    
    func fetchScan(id: UUID) -> ScanHistory? {
        let fetchRequest: NSFetchRequest<ScanHistory> = ScanHistory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try viewContext.fetch(fetchRequest).first
        } catch {
            return nil
        }
    }
    
    func fetchBluetoothDevices(scan: ScanHistory) -> [BluetoothDeviceHistory] {
        guard let devices = scan.bluetoothDevices as? Set<BluetoothDeviceHistory> else {
            return []
        }
        return Array(devices).sorted { $0.timestamp ?? Date() > $1.timestamp ?? Date() }
    }
    
    func fetchLANDevices(scan: ScanHistory) -> [LANDeviceHistory] {
        guard let devices = scan.lanDevices as? Set<LANDeviceHistory> else {
            return []
        }
        return Array(devices).sorted { $0.timestamp ?? Date() > $1.timestamp ?? Date() }
    }
    
    func deleteScan(scan: ScanHistory) {
        viewContext.delete(scan)
        saveContext()
    }
    
    func deleteAllScans() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ScanHistory.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            saveContext()
        } catch {
            print("Ошибка удаления истории сканирований: \(error)")
        }
    }
    
    func getStatistics() -> ScanStatistics {
        let fetchRequest: NSFetchRequest<ScanHistory> = ScanHistory.fetchRequest()
        
        do {
            let allScans = try viewContext.fetch(fetchRequest)
            
            var totalScans = 0
            var totalDevices = 0
            var totalBluetoothDevices = 0
            var totalLANDevices = 0
            var totalDuration: TimeInterval = 0
            
            for scan in allScans {
                totalScans += 1
                totalDevices += Int(scan.totalDevices)
                totalBluetoothDevices += Int(scan.bluetoothCount)
                totalLANDevices += Int(scan.lanCount)
                totalDuration += scan.duration
            }
            
            return ScanStatistics(
                totalScans: totalScans,
                totalDevices: totalDevices,
                totalBluetoothDevices: totalBluetoothDevices,
                totalLANDevices: totalLANDevices,
                averageDuration: totalScans > 0 ? totalDuration / Double(totalScans) : 0,
                lastScanDate: allScans.first?.timestamp
            )
        } catch {
            print("Ошибка получения статистики: \(error)")
            return ScanStatistics()
        }
    }
}

extension Notification.Name {
    static let scanHistoryUpdated = Notification.Name("scanHistoryUpdated")
}

struct ScanStatistics {
    let totalScans: Int
    let totalDevices: Int
    let totalBluetoothDevices: Int
    let totalLANDevices: Int
    let averageDuration: TimeInterval
    let lastScanDate: Date?
    
    init(totalScans: Int = 0,
         totalDevices: Int = 0,
         totalBluetoothDevices: Int = 0,
         totalLANDevices: Int = 0,
         averageDuration: TimeInterval = 0,
         lastScanDate: Date? = nil) {
        self.totalScans = totalScans
        self.totalDevices = totalDevices
        self.totalBluetoothDevices = totalBluetoothDevices
        self.totalLANDevices = totalLANDevices
        self.averageDuration = averageDuration
        self.lastScanDate = lastScanDate
    }
}
