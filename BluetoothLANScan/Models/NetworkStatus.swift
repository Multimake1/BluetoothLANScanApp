//
//  NetworkStatus.swift
//  BluetoothLANScan
//
//  Created by Арсений on 06.02.2026.
//

import Foundation
import SwiftUI

/// Перечисление всех возможных состояний сети и сканирования
enum NetworkStatus: Equatable {
    case ready
    case preparing
    case scanning
    case completed(ScanResult)
    case error(NetworkError)
    case stopped
    
    struct ScanResult: Equatable {
        let deviceCount: Int
        let duration: TimeInterval
        let foundDevices: Int
        
        var description: String {
            let durationText = formatDuration(duration: duration)
            return "Найдено \(foundDevices) устройств из \(deviceCount) за \(durationText)"
        }
        
        // Форматирование времени
        private func formatDuration(duration: TimeInterval) -> String {
            if duration < 1 {
                return "\(Int(duration * 1000))мс"
            } else if duration < 60 {
                return "\(Int(duration))с"
            } else {
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                return "\(minutes)м \(seconds)с"
            }
        }
    }
    
    enum NetworkError: Equatable {
        case bluetoothDisabled
        case wifiNotConnected
        case permissionDenied
        case scanFailed(String)
        case timeout
        
        var description: String {
            switch self {
            case .bluetoothDisabled:
                return "Bluetooth отключен"
            case .wifiNotConnected:
                return "Wi-Fi не подключен"
            case .permissionDenied:
                return "Нет разрешений"
            case .scanFailed(let reason):
                return "Ошибка сканирования: \(reason)"
            case .timeout:
                return "Таймаут сканирования"
            }
        }
    }
    
    // Текстовое представление состояния
    var displayText: String {
        switch self {
        case .ready:
            return "Готов к сканированию"
        case .preparing:
            return "Подготовка к сканированию..."
        case .scanning:
            return "Сканирование сети..."
        case .completed(let result):
            return "Завершено. \(result.description)"
        case .error(let error):
            return "Ошибка: \(error.description)"
        case .stopped:
            return "Сканирование остановлено"
        }
    }
    
    // Цвет для отображения состояния
    var color: NetworkStatusColor {
        switch self {
        case .ready, .completed:
            return .success
        case .preparing, .scanning:
            return .warning
        case .error:
            return .error
        case .stopped:
            return .neutral
        }
    }
    
    // Иконка для состояния
    var icon: String {
        switch self {
        case .ready:
            return "wifi"
        case .preparing:
            return "hourglass"
        case .scanning:
            return "antenna.radiowaves.left.and.right"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .stopped:
            return "stop.circle.fill"
        }
    }
    
    // Можно ли начать сканирование в этом состоянии
    var canStartScan: Bool {
        switch self {
        case .ready, .completed, .stopped, .error:
            return true
        case .preparing, .scanning:
            return false
        }
    }
    
    // Идет ли сейчас сканирование
    var isScanning: Bool {
        if case .scanning = self {
            return true
        }
        return false
    }
    
    // Завершено ли сканирование успешно
    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    // Есть ли ошибка
    var hasError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

extension NetworkStatus {
    static func == (lhs: NetworkStatus, rhs: NetworkStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready):
            return true
        case (.preparing, .preparing):
            return true
        case (.scanning, .scanning):
            return true
        case (.stopped, .stopped):
            return true
        case (.completed(let lhsResult), .completed(let rhsResult)):
            return lhsResult == rhsResult
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// Цвета для разных состояний
enum NetworkStatusColor {
    case success
    case warning
    case error
    case neutral
    
    var colorValue: Color {
        switch self {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .neutral:
            return .gray
        }
    }
}

extension NetworkStatusColor {
    var swiftUIColor: Color {
        colorValue
    }
}
