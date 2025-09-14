//
//  AlarmListViewModel.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import Combine

class AlarmListViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingAddAlarm: Bool = false
    @Published var selectedAlarm: Alarm?
    
    private let alarmService = AlarmService.shared
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadAlarms()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // アラームサービスの変更を監視
        alarmService.$alarms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alarms in
                self?.alarms = alarms.sorted { $0.time < $1.time }
            }
            .store(in: &cancellables)
        
        // 通知権限の状態を監視
        notificationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .denied {
                    self?.errorMessage = "通知権限が拒否されています。設定から有効にしてください。"
                } else {
                    self?.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadAlarms() {
        isLoading = true
        // アラームサービスから自動的に読み込まれる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
    
    // MARK: - Alarm Management
    
    func addAlarm(_ alarm: Alarm) {
        alarmService.addAlarm(alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        alarmService.updateAlarm(alarm)
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarmService.deleteAlarm(alarm)
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        alarmService.toggleAlarm(alarm)
    }
    
    // MARK: - UI Actions
    
    func showAddAlarm() {
        showingAddAlarm = true
    }
    
    func hideAddAlarm() {
        showingAddAlarm = false
    }
    
    func selectAlarm(_ alarm: Alarm) {
        selectedAlarm = alarm
    }
    
    func clearSelection() {
        selectedAlarm = nil
    }
    
    // MARK: - Computed Properties
    
    var enabledAlarms: [Alarm] {
        alarms.filter { $0.isEnabled }
    }
    
    var disabledAlarms: [Alarm] {
        alarms.filter { !$0.isEnabled }
    }
    
    var nextAlarm: Alarm? {
        alarmService.getNextAlarm()
    }
    
    var todayAlarms: [Alarm] {
        alarmService.getAlarmsForToday()
    }
    
    var hasAlarms: Bool {
        !alarms.isEmpty
    }
    
    var hasEnabledAlarms: Bool {
        !enabledAlarms.isEmpty
    }
    
    // MARK: - Notification Permission
    
    func requestNotificationPermission() async {
        let granted = await notificationService.requestPermission()
        if !granted {
            errorMessage = "通知権限が必要です。設定から有効にしてください。"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Alarm Actions
    
    func duplicateAlarm(_ alarm: Alarm) {
        var newAlarm = alarm
        newAlarm = Alarm(
            title: "\(alarm.title) のコピー",
            time: alarm.time,
            isEnabled: false, // コピーは無効状態で作成
            repeatDays: alarm.repeatDays,
            soundName: alarm.soundName,
            volume: alarm.volume,
            snoozeEnabled: alarm.snoozeEnabled,
            snoozeInterval: alarm.snoozeInterval,
            qrCodeRequired: alarm.qrCodeRequired,
            qrCodeData: alarm.qrCodeData
        )
        addAlarm(newAlarm)
    }
    
    func deleteAlarm(at indexSet: IndexSet) {
        for index in indexSet {
            let alarm = alarms[index]
            deleteAlarm(alarm)
        }
    }
    
    // MARK: - Sorting
    
    func sortAlarms(by sortType: SortType) {
        switch sortType {
        case .time:
            alarms = alarms.sorted { $0.time < $1.time }
        case .title:
            alarms = alarms.sorted { $0.title < $1.title }
        case .created:
            alarms = alarms.sorted { $0.createdAt > $1.createdAt }
        case .enabled:
            alarms = alarms.sorted { $0.isEnabled && !$1.isEnabled }
        }
    }
}

// MARK: - Sort Types

enum SortType: String, CaseIterable {
    case time = "時刻"
    case title = "タイトル"
    case created = "作成日時"
    case enabled = "有効/無効"
}
