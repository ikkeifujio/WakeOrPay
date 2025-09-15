//
//  AlarmService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import Combine
import UserNotifications

class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    @Published var alarms: [Alarm] = []
    @Published var isPlaying: Bool = false
    @Published var currentAlarm: Alarm?
    
    private let alarmsKey = "WakeOrPayAlarms"
    private var cancellables = Set<AnyCancellable>()
    private var alarmStartTime: Date?
    
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
        DispatchQueue.main.async {
            self.currentAlarm = alarm
            self.isPlaying = true
            self.alarmStartTime = Date() // アラーム開始時刻を記録
            
            // 音声再生（デバッグログ追加）
            print("音声再生開始: \(alarm.soundName)")
            SoundService.shared.playAlarmSound(alarm.soundName, volume: alarm.volume)
            
            // バイブレーション
            if AppSettings().alarmSettings.hapticFeedback {
                SoundService.shared.playHapticFeedback()
            }
            
            // QRコードが有効な場合はタイマーを開始
            if alarm.qrCodeRequired {
                print("QRコードタイマーを開始: \(alarm.id)")
                QRCodeTimerService.shared.startQRCodeTimer(for: alarm.id)
            }
            
            // アラーム開始の通知を送信
            NotificationCenter.default.post(name: .alarmTriggered, object: alarm)
            
            print("アラーム開始: \(alarm.title) at \(alarm.timeString)")
        }
    }
    
    func stopAlarm(_ alarmId: UUID) {
        if currentAlarm?.id == alarmId {
            stopCurrentAlarm()
        }
    }
    
    func stopCurrentAlarm() {
        DispatchQueue.main.async {
            // QRコードタイマーを停止
            if let alarmId = self.currentAlarm?.id {
                QRCodeTimerService.shared.stopQRCodeTimer(for: alarmId)
            }
            
            // 起床成功を記録
            if let alarm = self.currentAlarm, let startTime = self.alarmStartTime {
                let wakeUpTime = Date()
                let timeToWakeUp = wakeUpTime.timeIntervalSince(startTime)
                
                // 履歴機能は後で実装
                print("起床成功: \(alarm.title) - \(timeToWakeUp)秒")
            }
            
            self.isPlaying = false
            self.currentAlarm = nil
            self.alarmStartTime = nil
            SoundService.shared.stopAlarmSound()
        }
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
    
    // MARK: - Test Methods
    
    func testAlarm() {
        let testAlarm = Alarm(
            title: "テストアラーム",
            time: Date(),
            isEnabled: true,
            soundName: "default",
            volume: 0.8
        )
        startAlarm(testAlarm)
    }
    
    // MARK: - QR Code Methods
    
    // func startQRCodeTimer(for alarm: Alarm) {
    //     guard alarm.qrCodeRequired else { return }
    //     
    //     let qrCodeAlarm = QRCodeAlarm(
    //         alarmId: alarm.id,
    //         emergencyContact: "default_contact", // 設定から取得
    //         emergencyMessage: "\(alarm.title)のQRコードスキャンがタイムアウトしました"
    //     )
    //     
    //     QRCodeTimerService.shared.startQRCodeTimer(for: qrCodeAlarm)
    // }
    
    func validateQRCode(_ qrCodeData: String) -> Bool {
        print("QRコード検証開始: \(qrCodeData)")
        
        // QRCodeTimerServiceで検証
        let isValid = QRCodeTimerService.shared.validateQRCode(qrCodeData)
        
        if isValid {
            print("QRコードが有効です。アラームを停止します。")
            stopCurrentAlarm()
        } else {
            print("QRコードが無効です")
        }
        
        return isValid
    }
}

// MARK: - Notification Names

// MARK: - QR Code Timer Service

class QRCodeTimerService: ObservableObject {
    static let shared = QRCodeTimerService()
    
    private var timers: [UUID: Timer] = [:]
    private var alarmIds: [UUID: Date] = [:] // alarmId: 開始時刻
    
    private init() {}
    
    func startQRCodeTimer(for alarmId: UUID, timeoutDuration: TimeInterval = 180.0) {
        stopQRCodeTimer(for: alarmId) // 既存のタイマーがあれば停止
        
        alarmIds[alarmId] = Date()
        
        let timer = Timer.scheduledTimer(withTimeInterval: timeoutDuration, repeats: false) { [weak self] _ in
            self?.handleQRCodeTimeout(alarmId: alarmId)
        }
        timers[alarmId] = timer
        print("QRコードタイマー開始: \(alarmId) - \(timeoutDuration)秒")
    }
    
    func stopQRCodeTimer(for alarmId: UUID) {
        timers[alarmId]?.invalidate()
        timers[alarmId] = nil
        alarmIds[alarmId] = nil
        print("QRコードタイマー停止: \(alarmId)")
    }
    
            private func handleQRCodeTimeout(alarmId: UUID) {
                guard alarmIds[alarmId] != nil else {
                    print("タイムアウトしたアラームが見つかりません: \(alarmId)")
                    return
                }
                
                print("QRコードスキャンがタイムアウトしました: \(alarmId)")
                
                // 起床失敗を記録
                if let alarm = AlarmService.shared.currentAlarm {
                    print("起床失敗: \(alarm.title)")
                }
                
                // SMS緊急通知を送信
                SMSService.shared.sendEmergencySMS()
                
                // ローカル通知も送信
                sendLocalTimeoutNotification()
                
                // アラームを停止
                AlarmService.shared.stopCurrentAlarm()
                
                // タイマーを停止
                stopQRCodeTimer(for: alarmId)
            }
    
    private func sendLocalTimeoutNotification() {
        let content = UNMutableNotificationContent()
        content.title = "WakeOrPay 緊急通知"
        content.body = "QRコードスキャンがタイムアウトしました。SMSを送信しました。"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "qr-timeout-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ローカル通知送信エラー: \(error)")
            } else {
                print("ローカル通知を送信しました")
            }
        }
    }
    
    func validateQRCode(_ qrCodeData: String) -> Bool {
        // QRコードの形式をチェック: "WakeOrPay:Stop:<alarmId>"
        guard qrCodeData.hasPrefix("WakeOrPay:Stop:") else {
            print("QRコードの形式が正しくありません: \(qrCodeData)")
            return false
        }
        
        let alarmIdString = String(qrCodeData.dropFirst("WakeOrPay:Stop:".count))
        guard let alarmId = UUID(uuidString: alarmIdString) else {
            print("アラームIDが無効です: \(alarmIdString)")
            return false
        }
        
        // タイマーが動作中かチェック
        if timers[alarmId] != nil {
            print("QRコード検証成功: \(alarmId)")
            stopQRCodeTimer(for: alarmId)
            return true
        } else {
            print("QRコードは有効ですが、タイマーが動作していません: \(alarmId)")
            return false
        }
    }
    
    func isTimerRunning(for alarmId: UUID) -> Bool {
        return timers[alarmId] != nil
    }
    
    func getRemainingTime(for alarmId: UUID) -> TimeInterval? {
        guard let startTime = alarmIds[alarmId] else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, 180.0 - elapsed) // 3分 = 180秒
    }
}

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
    static let alarmStopped = Notification.Name("alarmStopped")
}
