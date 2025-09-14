//
//  ContentView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var alarmService = AlarmService.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingAlarmView = false
    
    var body: some View {
        AlarmListView()
            .environmentObject(alarmService)
            .environmentObject(notificationService)
            .onAppear {
                setupApp()
            }
    }
    
    private func setupApp() {
        // 通知カテゴリの設定
        notificationService.setupNotificationCategories()
        
        // 通知権限のリクエスト
        Task {
            await notificationService.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
