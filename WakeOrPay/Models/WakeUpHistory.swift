//
//  WakeUpHistory.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/15.
//

import Foundation

struct WakeUpHistory: Codable, Identifiable {
    let id: UUID
    let date: Date
    let alarmId: UUID
    let alarmTitle: String
    let wakeUpTime: Date
    let qrCodeScanned: Bool
    let timeToWakeUp: TimeInterval // アラームから起きるまでの時間（秒）
    
    init(alarmId: UUID, alarmTitle: String, wakeUpTime: Date, qrCodeScanned: Bool, timeToWakeUp: TimeInterval) {
        self.id = UUID()
        self.date = Date()
        self.alarmId = alarmId
        self.alarmTitle = alarmTitle
        self.wakeUpTime = wakeUpTime
        self.qrCodeScanned = qrCodeScanned
        self.timeToWakeUp = timeToWakeUp
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeUpTime)
    }
    
    var timeToWakeUpString: String {
        let minutes = Int(timeToWakeUp / 60)
        let seconds = Int(timeToWakeUp.truncatingRemainder(dividingBy: 60))
        return "\(minutes)分\(seconds)秒"
    }
}

// MARK: - Wake Up Statistics

struct WakeUpStatistics {
    let totalWakeUps: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageTimeToWakeUp: TimeInterval
    let qrCodeSuccessRate: Double
    
    var currentStreakString: String {
        return "\(currentStreak)日連続"
    }
    
    var longestStreakString: String {
        return "\(longestStreak)日連続"
    }
    
    var averageTimeString: String {
        let minutes = Int(averageTimeToWakeUp / 60)
        let seconds = Int(averageTimeToWakeUp.truncatingRemainder(dividingBy: 60))
        return "\(minutes)分\(seconds)秒"
    }
    
    var qrCodeSuccessRateString: String {
        return String(format: "%.1f%%", qrCodeSuccessRate * 100)
    }
}
