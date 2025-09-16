//
//  Alarm.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var time: Date
    var isEnabled: Bool
    var repeatDays: Set<Weekday>
    var soundName: String
    var volume: Float
    var snoozeEnabled: Bool
    var snoozeInterval: Int // minutes
    var qrCodeRequired: Bool
    var qrCodeData: String?
    var expectedQR: String // 期待するQRコード（"Universal"またはアラームID）
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "アラーム",
        time: Date = Date(),
        isEnabled: Bool = true,
        repeatDays: Set<Weekday> = [],
        soundName: String = "default",
        volume: Float = 0.8,
        snoozeEnabled: Bool = true,
        snoozeInterval: Int = 5,
        qrCodeRequired: Bool = true,
        qrCodeData: String? = nil,
        expectedQR: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.soundName = soundName
        self.volume = volume
        self.snoozeEnabled = snoozeEnabled
        self.snoozeInterval = snoozeInterval
        self.qrCodeRequired = qrCodeRequired
        self.qrCodeData = qrCodeData
        self.expectedQR = expectedQR ?? "Universal" // デフォルトはUniversal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 次のアラーム時刻を計算
    func nextAlarmTime() -> Date? {
        guard isEnabled else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let alarmTime = calendar.dateComponents([.hour, .minute], from: time)
        
        // 今日のアラーム時刻
        guard let todayAlarmTime = calendar.date(bySettingHour: alarmTime.hour ?? 0, 
                                               minute: alarmTime.minute ?? 0, 
                                               second: 0, 
                                               of: today) else { return nil }
        
        // 今日のアラームがまだ来ていない場合
        if todayAlarmTime > now {
            // 今日の曜日がリピート対象かチェック
            let todayWeekday = Weekday.from(calendar.component(.weekday, from: now))
            if repeatDays.isEmpty || repeatDays.contains(todayWeekday) {
                return todayAlarmTime
            }
        }
        
        // 次のリピート日を探す
        for dayOffset in 1...7 {
            guard let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let nextWeekday = Weekday.from(calendar.component(.weekday, from: nextDay))
            
            if repeatDays.isEmpty || repeatDays.contains(nextWeekday) {
                return calendar.date(bySettingHour: alarmTime.hour ?? 0,
                                  minute: alarmTime.minute ?? 0,
                                  second: 0,
                                  of: nextDay)
            }
        }
        
        return nil
    }
    
    // 時間表示用の文字列
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    // リピート表示用の文字列
    var repeatString: String {
        if repeatDays.isEmpty {
            return "一度だけ"
        }
        
        let sortedDays = repeatDays.sorted { $0.rawValue < $1.rawValue }
        let dayNames = sortedDays.map { $0.shortName }
        return dayNames.joined(separator: ", ")
    }
}

enum Weekday: Int, CaseIterable, Codable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
        case .sunday: return "日曜日"
        case .monday: return "月曜日"
        case .tuesday: return "火曜日"
        case .wednesday: return "水曜日"
        case .thursday: return "木曜日"
        case .friday: return "金曜日"
        case .saturday: return "土曜日"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "月"
        case .tuesday: return "火"
        case .wednesday: return "水"
        case .thursday: return "木"
        case .friday: return "金"
        case .saturday: return "土"
        }
    }
    
    static func from(_ weekday: Int) -> Weekday {
        return Weekday(rawValue: weekday) ?? .sunday
    }
}
