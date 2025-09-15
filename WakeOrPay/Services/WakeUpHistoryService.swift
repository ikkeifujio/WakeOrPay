//
//  WakeUpHistoryService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/15.
//

import Foundation
import Combine

class WakeUpHistoryService: ObservableObject {
    static let shared = WakeUpHistoryService()
    
    @Published var histories: [WakeUpHistory] = []
    @Published var statistics: WakeUpStatistics = WakeUpStatistics(
        totalWakeUps: 0,
        currentStreak: 0,
        longestStreak: 0,
        averageTimeToWakeUp: 0,
        qrCodeSuccessRate: 0
    )
    
    private let historiesKey = "WakeUpHistories"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadHistories()
        calculateStatistics()
    }
    
    // MARK: - History Management
    
    func addWakeUpHistory(alarmId: UUID, alarmTitle: String, wakeUpTime: Date, qrCodeScanned: Bool, timeToWakeUp: TimeInterval) {
        let history = WakeUpHistory(
            alarmId: alarmId,
            alarmTitle: alarmTitle,
            wakeUpTime: wakeUpTime,
            qrCodeScanned: qrCodeScanned,
            timeToWakeUp: timeToWakeUp
        )
        
        histories.append(history)
        saveHistories()
        calculateStatistics()
        
        print("起床履歴を追加: \(history.dateString) \(history.timeString)")
    }
    
    func addFailedWakeUp(alarmId: UUID, alarmTitle: String) {
        // QRコードをスキャンできなかった場合、連続記録をリセット
        let history = WakeUpHistory(
            alarmId: alarmId,
            alarmTitle: alarmTitle,
            wakeUpTime: Date(),
            qrCodeScanned: false,
            timeToWakeUp: 0
        )
        
        histories.append(history)
        saveHistories()
        calculateStatistics()
        
        print("起床失敗を記録: \(history.dateString)")
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStatistics() {
        let totalWakeUps = histories.count
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        let averageTimeToWakeUp = calculateAverageTimeToWakeUp()
        let qrCodeSuccessRate = calculateQRCodeSuccessRate()
        
        statistics = WakeUpStatistics(
            totalWakeUps: totalWakeUps,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageTimeToWakeUp: averageTimeToWakeUp,
            qrCodeSuccessRate: qrCodeSuccessRate
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        // 今日から過去に向かって連続日数を計算
        for i in 0..<histories.count {
            let checkDate = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayHistories = histories.filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
            
            if dayHistories.contains(where: { $0.qrCodeScanned }) {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        let sortedHistories = histories.sorted { $0.date < $1.date }
        
        for history in sortedHistories {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: history.date).day ?? 0
                
                if daysBetween == 1 && history.qrCodeScanned {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = history.qrCodeScanned ? 1 : 0
                } else if !history.qrCodeScanned {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 0
                }
            } else if history.qrCodeScanned {
                currentStreak = 1
            }
            
            lastDate = history.date
        }
        
        return max(maxStreak, currentStreak)
    }
    
    private func calculateAverageTimeToWakeUp() -> TimeInterval {
        let successfulWakeUps = histories.filter { $0.qrCodeScanned && $0.timeToWakeUp > 0 }
        
        guard !successfulWakeUps.isEmpty else { return 0 }
        
        let totalTime = successfulWakeUps.reduce(0) { $0 + $1.timeToWakeUp }
        return totalTime / Double(successfulWakeUps.count)
    }
    
    private func calculateQRCodeSuccessRate() -> Double {
        guard !histories.isEmpty else { return 0 }
        
        let successfulScans = histories.filter { $0.qrCodeScanned }.count
        return Double(successfulScans) / Double(histories.count)
    }
    
    // MARK: - Data Persistence
    
    private func loadHistories() {
        guard let data = UserDefaults.standard.data(forKey: historiesKey),
              let loadedHistories = try? JSONDecoder().decode([WakeUpHistory].self, from: data) else {
            return
        }
        histories = loadedHistories
    }
    
    private func saveHistories() {
        if let data = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(data, forKey: historiesKey)
        }
    }
    
    // MARK: - Utility Methods
    
    func getHistoriesForDate(_ date: Date) -> [WakeUpHistory] {
        let calendar = Calendar.current
        return histories.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getRecentHistories(limit: Int = 10) -> [WakeUpHistory] {
        return Array(histories.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    func clearAllHistories() {
        histories.removeAll()
        saveHistories()
        calculateStatistics()
    }
}
