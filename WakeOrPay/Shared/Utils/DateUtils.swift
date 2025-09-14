//
//  DateUtils.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation

struct DateUtils {
    
    // MARK: - Date Formatting
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.TimeFormat.time
        return formatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.TimeFormat.dateTime
        return formatter.string(from: date)
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.TimeFormat.date
        return formatter.string(from: date)
    }
    
    // MARK: - Date Calculation
    
    static func getNextWeekday(_ weekday: Weekday, from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let todayWeekday = Weekday.from(calendar.component(.weekday, from: today))
        
        let daysUntilTarget = (weekday.rawValue - todayWeekday.rawValue + 7) % 7
        let daysToAdd = daysUntilTarget == 0 ? 7 : daysUntilTarget
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    static func isTomorrow(_ date: Date) -> Bool {
        Calendar.current.isDateInTomorrow(date)
    }
    
    static func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    // MARK: - Time Components
    
    static func getHour(_ date: Date) -> Int {
        Calendar.current.component(.hour, from: date)
    }
    
    static func getMinute(_ date: Date) -> Int {
        Calendar.current.component(.minute, from: date)
    }
    
    static func getWeekday(_ date: Date) -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: date)
        return Weekday.from(weekday)
    }
    
    // MARK: - Date Creation
    
    static func createDate(hour: Int, minute: Int, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
    }
    
    static func createDateFromTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.TimeFormat.time
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
    }
    
    // MARK: - Relative Time
    
    static func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "過去"
        }
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if minutes < 60 {
            return "\(minutes)分後"
        } else if hours < 24 {
            return "\(hours)時間後"
        } else {
            return "\(days)日後"
        }
    }
    
    // MARK: - Weekday Helpers
    
    static func getWeekdayNames() -> [String] {
        return Weekday.allCases.map { $0.name }
    }
    
    static func getShortWeekdayNames() -> [String] {
        return Weekday.allCases.map { $0.shortName }
    }
    
    // MARK: - Time Validation
    
    static func isValidTime(hour: Int, minute: Int) -> Bool {
        return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59
    }
    
    static func isValidTimeString(_ timeString: String) -> Bool {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return false
        }
        return isValidTime(hour: hour, minute: minute)
    }
}
