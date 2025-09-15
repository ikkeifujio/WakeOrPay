//
//  HistoryView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/15.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var historyService = WakeUpHistoryService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // タブ選択
                Picker("表示", selection: $selectedTab) {
                    Text("統計").tag(0)
                    Text("履歴").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    statisticsView
                } else {
                    historyListView
                }
            }
            .navigationTitle("起床履歴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Statistics View
    
    private var statisticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 連続記録カード
                VStack(spacing: 12) {
                    Text("現在の連続記録")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(historyService.statistics.currentStreakString)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("日連続")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                
                // 統計情報グリッド
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "総起床回数",
                        value: "\(historyService.statistics.totalWakeUps)回",
                        icon: "alarm.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "最長記録",
                        value: historyService.statistics.longestStreakString,
                        icon: "trophy.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "平均起床時間",
                        value: historyService.statistics.averageTimeString,
                        icon: "clock.fill",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "QR成功率",
                        value: historyService.statistics.qrCodeSuccessRateString,
                        icon: "qrcode",
                        color: .cyan
                    )
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - History List View
    
    private var historyListView: some View {
        List {
            ForEach(historyService.getRecentHistories()) { history in
                HistoryRowView(history: history)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let history: WakeUpHistory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.alarmTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(history.dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(history.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if history.qrCodeScanned {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("成功")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text(history.timeToWakeUpString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("失敗")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
