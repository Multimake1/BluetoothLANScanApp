//
//  ScanHistoryView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI

struct ScanHistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                FilterPanelView(
                    searchText: $viewModel.searchText,
                    timeFilter: $viewModel.selectedTimeFilter,
                    onSearchChanged: { viewModel.loadScans() },
                    onTimeFilterChanged: { viewModel.loadScans() }
                )
                
                if viewModel.scans.isEmpty {
                    EmptyHistoryView(searchText: viewModel.searchText, timeFilter: viewModel.selectedTimeFilter)
                } else {
                    List {
                        ForEach(viewModel.scans) { scan in
                            NavigationLink(destination: ScanDetailView(scan: scan)) {
                                ScanRowView(scan: scan)
                            }
                        }
                        .onDelete { indexSet in
                            deleteScans(at: indexSet)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("История сканирований")
            .toolbar {
                if !viewModel.scans.isEmpty {
                    EditButton()
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func deleteScans(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                let scan = viewModel.scans[index]
                viewModel.deleteScan(scan: scan)
            }
        }
    }
}

struct FilterPanelView: View {
    @Binding var searchText: String
    @Binding var timeFilter: TimeFilter
    let onSearchChanged: () -> Void
    let onTimeFilterChanged: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Поиск по устройству", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        onSearchChanged()
                    }
                
                if !searchText.isEmpty {
                    Button("Очистить") {
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeFilter.allCases) { filter in
                        TimeFilterButton(
                            filter: filter,
                            isSelected: timeFilter == filter
                        ) {
                            timeFilter = filter
                            onTimeFilterChanged()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGray6))
    }
}

struct TimeFilterButton: View {
    let filter: TimeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ScanRowView: View {
    let scan: ScanHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatDate(scan.timestamp ?? Date()))
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                if scan.bluetoothCount > 0 {
                    Label("\(scan.bluetoothCount)", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if scan.lanCount > 0 {
                    Label("\(scan.lanCount)", systemImage: "network")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("Всего: \(scan.totalDevices)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
