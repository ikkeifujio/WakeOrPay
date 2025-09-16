//
//  NotificationService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("通知権限のリクエストに失敗: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func scheduleAlarm(_ alarm: Alarm) {
        guard alarm.isEnabled else { return }
        
        // 既存の通知を削除
        removeAlarmNotification(alarm.id)
        
        // 次のアラーム時刻を計算
        guard let nextAlarmTime = alarm.nextAlarmTime() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "WakeOrPay"
        content.body = alarm.title
        
        // システムのデフォルトサウンドを使用（最も確実）
        content.sound = UNNotificationSound.default
        print("システムデフォルトサウンドを使用")
        
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "snoozeEnabled": alarm.snoozeEnabled,
            "snoozeInterval": alarm.snoozeInterval,
            "qrCodeRequired": alarm.qrCodeRequired,
            "fireDate": nextAlarmTime.timeIntervalSince1970 // fireDateを保存
        ]
        
        // トリガー設定
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextAlarmTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("アラーム通知のスケジュールに失敗: \(error)")
            } else {
                print("アラーム通知をスケジュールしました: \(alarm.title) at \(nextAlarmTime)")
            }
        }
    }
    
    func removeAlarmNotification(_ alarmId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmId.uuidString])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "スヌーズ",
            options: []
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "停止",
            options: [.destructive]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else { return }
        
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            handleSnoozeAction(alarmId: alarmId, userInfo: userInfo)
        case "STOP_ACTION":
            handleStopAction(alarmId: alarmId)
        case UNNotificationDefaultActionIdentifier:
            // 通知タップ時にアラームを開始
            startAlarmFromNotification(alarmId: alarmId, userInfo: userInfo)
        default:
            break
        }
    }
    
    private func handleSnoozeAction(alarmId: UUID, userInfo: [AnyHashable: Any]) {
        guard let snoozeInterval = userInfo["snoozeInterval"] as? Int else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "WakeOrPay - スヌーズ"
        content.body = "\(snoozeInterval)分後に再びアラームが鳴ります"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeInterval * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarmId.uuidString)_snooze",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("スヌーズ通知のスケジュールに失敗: \(error)")
            }
        }
    }
    
    private func handleStopAction(alarmId: UUID) {
        removeAlarmNotification(alarmId)
        // アラームサービスに停止を通知
        AlarmService.shared.stopAlarm(alarmId)
    }
    
    func startAlarmFromNotification(alarmId: UUID, userInfo: [AnyHashable: Any]) {
        // アラームIDからアラーム情報を取得
        let alarmService = AlarmService.shared
        guard let alarm = alarmService.getAlarm(by: alarmId) else {
            print("通知からアラーム情報を取得できませんでした: \(alarmId)")
            return
        }
        
        print("通知からアラームを開始: \(alarm.title)")
        
        // 通知からアプリを開いた場合は、状態復元フラグを設定してダイアログ表示を防ぐ
        alarmService.setNotificationLaunchFlag(true)
        
        // 実際のアラーム開始（通知は送信しない）
        alarmService.startAlarm(alarm)
    }
}
