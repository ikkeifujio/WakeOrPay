//
//  WakeOrPayApp.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UserNotifications

@main
struct WakeOrPayApp: App {
    init() {
        // 通知ハンドラーを設定
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationService.shared.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    override init() {
        super.init()
    }
    
    // アプリがフォアグラウンドで通知を受け取った時
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("フォアグラウンドで通知を受信: \(notification.request.content.title)")
        
        // 通知からアラームを開始
        let userInfo = notification.request.content.userInfo
        if let alarmIdString = userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            NotificationService.shared.startAlarmFromNotification(alarmId: alarmId, userInfo: userInfo)
        }
        
        // 通知を表示しない（アラームが開始されるため）
        completionHandler([])
    }
    
    // 通知がタップされた時
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("通知がタップされました: \(response.actionIdentifier)")
        
        NotificationService.shared.handleNotificationResponse(response)
        completionHandler()
    }
}
