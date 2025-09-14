//
//  AlarmService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import Combine

class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    @Published var alarms: [Alarm] = []
    @Published var isPlaying: Bool = false
    @Published var currentAlarm: Alarm?
    
    private let alarmsKey = "WakeOrPayAlarms"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadAlarms()
        setupNotificationHandling()
    }
    
    // MARK: - Alarm Management
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        NotificationService.shared.scheduleAlarm(alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
            NotificationService.shared.scheduleAlarm(alarm)
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        NotificationService.shared.removeAlarmNotification(alarm.id)
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        var updatedAlarm = alarm
        updatedAlarm.isEnabled.toggle()
        updatedAlarm.updatedAt = Date()
        updateAlarm(updatedAlarm)
    }
    
    // MARK: - Alarm Playback
    
    func startAlarm(_ alarm: Alarm) {
        currentAlarm = alarm
        isPlaying = true
        
        // 音声再生
        SoundService.shared.playAlarmSound(alarm.soundName, volume: alarm.volume)
        
        // バイブレーション
        if AppSettings().alarmSettings.hapticFeedback {
            SoundService.shared.playHapticFeedback()
        }
    }
    
    func stopAlarm(_ alarmId: UUID) {
        if currentAlarm?.id == alarmId {
            stopCurrentAlarm()
        }
    }
    
    func stopCurrentAlarm() {
        isPlaying = false
        currentAlarm = nil
        SoundService.shared.stopAlarmSound()
    }
    
    func snoozeAlarm(_ alarm: Alarm) {
        stopCurrentAlarm()
        
        // スヌーズ通知をスケジュール
        let snoozeTime = Date().addingTimeInterval(TimeInterval(alarm.snoozeInterval * 60))
        var snoozeAlarm = alarm
        snoozeAlarm.time = snoozeTime
        snoozeAlarm.isEnabled = true
        
        NotificationService.shared.scheduleAlarm(snoozeAlarm)
    }
    
    // MARK: - Data Persistence
    
    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey),
              let loadedAlarms = try? JSONDecoder().decode([Alarm].self, from: data) else {
            return
        }
        alarms = loadedAlarms
    }
    
    private func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: alarmsKey)
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationHandling() {
        NotificationCenter.default.publisher(for: .alarmTriggered)
            .sink { [weak self] notification in
                if let alarm = notification.object as? Alarm {
                    self?.startAlarm(alarm)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Utility Methods
    
    func getNextAlarm() -> Alarm? {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        let nextAlarms = enabledAlarms.compactMap { alarm -> (Alarm, Date)? in  // ← ?を追加
            guard let nextTime = alarm.nextAlarmTime() else { return nil }
            return (alarm, nextTime)
        }
        return nextAlarms.min(by: { $0.1 < $1.1 })?.0
    }
    
    func getAlarmsForToday() -> [Alarm] {
        let today = Date()
        let calendar = Calendar.current
        let todayWeekday = Weekday.from(calendar.component(.weekday, from: today))
        
        return alarms.filter { alarm in
            guard alarm.isEnabled else { return false }
            
            // リピート設定がない場合は今日のアラームのみ
            if alarm.repeatDays.isEmpty {
                return calendar.isDate(alarm.time, inSameDayAs: today)
            }
            
            // リピート設定がある場合は今日の曜日が含まれているかチェック
            return alarm.repeatDays.contains(todayWeekday)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
    static let alarmStopped = Notification.Name("alarmStopped")
}
