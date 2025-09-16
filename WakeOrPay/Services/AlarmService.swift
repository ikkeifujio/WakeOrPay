//
//  AlarmService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import Combine
import UserNotifications
import UIKit
import MessageUI

class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    @Published var alarms: [Alarm] = []
    @Published var isPlaying: Bool = false
    @Published var currentAlarm: Alarm?
    @Published var alarmState: AlarmState = .idle
    @Published var showingSuccessDialog: Bool = false
    @Published var showingFailureDialog: Bool = false
    private var isRestoringState: Bool = false
    private var isNotificationLaunch: Bool = false
    
    private let alarmsKey = "WakeOrPayAlarms"
    private var cancellables = Set<AnyCancellable>()
        var alarmStartTime: Date?
    private let stateLock = NSLock() // 状態変更の排他制御
    
    private init() {
        // ダイアログ状態を初期化（強制的に非表示）
        showingSuccessDialog = false
        showingFailureDialog = false
        
        // アプリ起動時は状態復元フラグを設定
        isRestoringState = true
        
        // アプリ起動時間を記録
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "app_launch_time")
        
        // QRスキャン成功フラグをクリア（アプリ起動時は成功ダイアログを表示しない）
        UserDefaults.standard.set(false, forKey: "qr_scan_success")
        
        // 通知起動フラグもクリア
        isNotificationLaunch = false
        
        // アプリ起動フラグを設定（成功ダイアログ防止用）
        UserDefaults.standard.set(true, forKey: "app_just_started")
        
        loadAlarms()
        setupNotificationHandling()
        restoreAlarmStateOnLaunch()
        
        // アプリ起動時は絶対に成功ダイアログを表示しない（即座に実行）
        DispatchQueue.main.async {
            self.showingSuccessDialog = false
            self.showingFailureDialog = false
            print("AlarmService: アプリ起動時 - ダイアログを強制非表示")
        }
        
        // アプリ起動後も確実にダイアログを非表示にする（複数回実行）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideAllDialogs()
            print("AlarmService: 0.1秒後 - ダイアログを強制非表示")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.hideAllDialogs()
            print("AlarmService: 1秒後 - ダイアログを強制非表示")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.hideAllDialogs()
            print("AlarmService: 5秒後 - ダイアログを強制非表示")
        }
        
        // アプリ復帰時もダイアログを非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.hideAllDialogs()
            print("AlarmService: 10秒後 - ダイアログを強制非表示")
        }
        
        // さらに強制的にダイアログを非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.hideAllDialogs()
            print("AlarmService: 15秒後 - ダイアログを強制非表示")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            self.hideAllDialogs()
            print("AlarmService: 20秒後 - ダイアログを強制非表示")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 35.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 45.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 55.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 75.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 100.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 115.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 150.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 200.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 250.0) {
            self.hideAllDialogs()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 290.0) {
            self.hideAllDialogs()
        }
        
        // アプリ起動フラグをリセット（10秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            UserDefaults.standard.set(false, forKey: "app_just_started")
            print("AlarmService: アプリ起動フラグをリセット")
        }
    }
    
    // MARK: - Alarm State Management
    
    enum AlarmState {
        case idle
        case active
        case success
        case failure
        
        var isTerminalState: Bool {
            return self == .success || self == .failure
        }
        
        var canTransitionToSuccess: Bool {
            return self == .active
        }
        
        var canTransitionToFailure: Bool {
            return self == .active
        }
        
        var canMarkSuccess: Bool {
            return self == .active
        }
    }
    
    internal func setAlarmState(_ newState: AlarmState) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        // 終端状態からの遷移を防ぐ
        if alarmState.isTerminalState && newState != .idle {
            print("⚠️ AlarmService: 終端状態(\(alarmState))から状態変更を拒否: \(newState)")
            return
        }
        
        // 成功状態への遷移を検証
        if newState == .success && !alarmState.canTransitionToSuccess {
            print("⚠️ AlarmService: 成功状態への遷移を拒否: \(alarmState) -> \(newState)")
            return
        }
        
        // 失敗状態への遷移を検証
        if newState == .failure && !alarmState.canTransitionToFailure {
            print("⚠️ AlarmService: 失敗状態への遷移を拒否: \(alarmState) -> \(newState)")
            return
        }
        
        print("AlarmService: 状態変更 \(alarmState) -> \(newState)")
        alarmState = newState
        
        // メインスレッドでUI更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - State Restoration
    
    private func restoreAlarmStateOnLaunch() {
        print("=== アプリ起動時の状態復元開始 ===")
        
        // 既に終端状態の場合は復元しない
        if alarmState.isTerminalState {
            print("⚠️ 既に終端状態(\(alarmState))のため、状態復元をスキップ")
            clearSavedAlarmState()
            return
        }
        
        // 保存されたアラーム状態を確認
        if let savedAlarmId = UserDefaults.standard.string(forKey: "currentAlarmId"),
           let savedStartTime = UserDefaults.standard.object(forKey: "alarmStartTime") as? Date {
            
            print("保存されたアラーム状態を発見:")
            print("  アラームID: \(savedAlarmId)")
            print("  開始時刻: \(savedStartTime)")
            
            // 対応するアラームを見つける
            if let alarm = alarms.first(where: { $0.id.uuidString == savedAlarmId }) {
                print("対応するアラームを発見: \(alarm.title)")
                
                // 現在時刻がアラーム時刻以降かチェック
                let now = Date()
                let timeSinceStart = now.timeIntervalSince(savedStartTime)
                
                print("現在時刻: \(now)")
                print("開始からの経過時間: \(String(format: "%.1f", timeSinceStart))秒")
                
                // アラームが開始されてから60秒以内の場合、Ringing状態に復元
                if timeSinceStart >= 0 && timeSinceStart <= 60 {
                    print("✅ アラーム状態を復元します")
                    
                    DispatchQueue.main.async {
                        self.currentAlarm = alarm
                        self.alarmStartTime = savedStartTime
                        self.setAlarmState(.active)
                        self.isPlaying = true
                        
                        // アラーム音を開始
                        SoundService.shared.playAlarmSound(alarm.soundName, volume: alarm.volume)
                        
                        // 状態復元時はダイアログを表示しない
                        self.hideAllDialogs()
                        
                        // 状態復元完了後にフラグをリセット（さらに長い時間待機）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0) {
                            self.isRestoringState = false
                            print("状態復元フラグをリセットしました")
                        }
                        
                        print("✅ アラーム状態復元完了")
                        print("   アラーム: \(alarm.title)")
                        print("   状態: \(self.alarmState)")
                        print("   再生中: \(self.isPlaying)")
                    }
                } else {
                    print("❌ アラーム時刻を過ぎているため復元しません")
                    clearSavedAlarmState()
                }
            } else {
                print("❌ 対応するアラームが見つかりません")
                clearSavedAlarmState()
            }
        } else {
            print("保存されたアラーム状態がありません")
        }
        
        print("=== アプリ起動時の状態復元完了 ===")
    }
    
    private func clearSavedAlarmState() {
        UserDefaults.standard.removeObject(forKey: "currentAlarmId")
        UserDefaults.standard.removeObject(forKey: "alarmStartTime")
        print("保存されたアラーム状態をクリアしました")
    }
    
    private func saveAlarmState(alarmId: UUID, startTime: Date) {
        UserDefaults.standard.set(alarmId.uuidString, forKey: "currentAlarmId")
        UserDefaults.standard.set(startTime, forKey: "alarmStartTime")
        print("アラーム状態を保存しました: \(alarmId.uuidString), \(startTime)")
    }
    
    // MARK: - Dialog Management
    
    func showSuccessDialog() {
        print("AlarmService: showSuccessDialog called - 完全ブロック中")
        
        // 絶対に成功ダイアログを表示しない（即座に実行）
        self.showingSuccessDialog = false
        self.showingFailureDialog = false
        
        // さらに強制的に非表示にする
        DispatchQueue.main.async {
            print("AlarmService: 成功ダイアログを完全ブロック")
            self.showingSuccessDialog = false
            self.showingFailureDialog = false
        }
        
        // このメソッドは何も表示しない
        return
    }
    
    func showFailureDialog() {
        DispatchQueue.main.async {
            print("AlarmService: 失敗ダイアログを表示")
            self.showingSuccessDialog = false // 成功ダイアログを非表示
            self.showingFailureDialog = true
        }
    }
    
    func hideAllDialogs() {
        DispatchQueue.main.async {
            print("AlarmService: すべてのダイアログを非表示")
            self.showingSuccessDialog = false
            self.showingFailureDialog = false
        }
    }
    
    func markSuccessIfValidScan() {
        DispatchQueue.main.async {
            print("AlarmService: Marking success from valid QR scan")
            
            // ONLY allow success if alarm is in active state
            guard self.alarmState.canMarkSuccess else {
                print("AlarmService: Cannot mark success - alarm not in active state: \(self.alarmState)")
                return
            }
            
            // Set QR scan success flag
            UserDefaults.standard.set(true, forKey: "qr_scan_success")
            
            // Change state to success (CENTRALIZED)
            self.setAlarmState(.success)
            
            // Stop alarm
            self.stopCurrentAlarm()
            
            // Send success notification (centralized dialog management)
            NotificationCenter.default.post(name: .alarmDidSucceed, object: nil)
            NotificationCenter.default.post(name: .qrScanSuccess, object: nil)
            
            print("AlarmService: Success processing completed")
        }
    }
    
    func resetToIdleState() {
        DispatchQueue.main.async {
            print("AlarmService: Resetting to idle state (centralized)")
            
            // Only reset if not in terminal state (prevent external resets)
            guard !self.alarmState.isTerminalState else {
                print("AlarmService: Cannot reset - in terminal state: \(self.alarmState)")
                return
            }
            
            self.setAlarmState(.idle)
            self.hideAllDialogs()
            self.clearSavedAlarmState()
            
            // Clear QR scan success flag
            UserDefaults.standard.set(false, forKey: "qr_scan_success")
        }
    }
    
    func setNotificationLaunchFlag(_ flag: Bool) {
        DispatchQueue.main.async {
            self.isNotificationLaunch = flag
            print("AlarmService: 通知起動フラグを設定: \(flag)")
            
            // 通知起動フラグが設定された場合は、一定時間後にリセット
            if flag {
                DispatchQueue.main.asyncAfter(deadline: .now() + 300.0) {
                    self.isNotificationLaunch = false
                    print("AlarmService: 通知起動フラグをリセット")
                }
            }
        }
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
            // 重複開始を防止
            if self.alarmState == .active {
                print("⚠️ アラームは既にアクティブ状態です - 重複開始を防止")
                return
            }
            
            // 終端状態の場合は自動的にリセットしてから開始
            if self.alarmState.isTerminalState {
                print("⚠️ 終端状態(\(self.alarmState))を検出 - 自動的にidle状態にリセット")
                self.resetToIdleState()
                
                // リセット後に少し待機
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.startAlarmInternal(alarm)
                }
                return
            }
            
            // 内部の開始処理を呼び出し
            self.startAlarmInternal(alarm)
        }
    }
    
    private func startAlarmInternal(_ alarm: Alarm) {
        DispatchQueue.main.async {
            // 既存のアラームを停止
            if self.currentAlarm != nil {
                print("既存のアラームを停止してから新しいアラームを開始")
                self.stopCurrentAlarm()
            }
            
            print("=== アラーム開始処理 ===")
            print("アラーム: \(alarm.title)")
            print("音声: \(alarm.soundName)")
            print("音量: \(alarm.volume)")
            print("QRコード必要: \(alarm.qrCodeRequired)")
            print("現在の状態: \(self.alarmState)")
            
            // 状態をアクティブに設定
            self.setAlarmState(.active)
            
            self.currentAlarm = alarm
            self.isPlaying = true
            self.alarmStartTime = Date() // アラーム開始時刻を記録
            
            // 状態を保存（アプリ再起動時の復元用）
            self.saveAlarmState(alarmId: alarm.id, startTime: self.alarmStartTime!)
            
            print("AlarmService: アラーム開始 - \(alarm.title), 状態: \(self.alarmState)")
            
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
                
                // サーバーにアラームを登録（自動SMS送信用）
                if let phoneNumber = self.getEmergencyPhoneNumber(),
                   let startTime = self.alarmStartTime {
                    Task {
                        await ServerWebhookService.shared.registerAlarm(
                            alarmId: alarm.id,
                            fireDate: startTime,
                            phoneNumber: phoneNumber
                        )
                    }
                    print("ServerWebhookService: アラーム登録完了 - \(alarm.id)")
                } else {
                    print("ServerWebhookService: 緊急連絡先または開始時刻が設定されていません")
                }
            }
            
            // アラーム開始の通知を送信
            print("アラーム開始通知を送信: \(alarm.title)")
            NotificationCenter.default.post(name: .alarmTriggered, object: alarm)
            
            print("アラーム開始完了: \(alarm.title) at \(alarm.timeString)")
        }
    }
    
    func getAlarm(by alarmId: UUID) -> Alarm? {
        return alarms.first { $0.id == alarmId }
    }
    
        func getEmergencyPhoneNumber() -> String? {
            return UserDefaults.standard.string(forKey: "EMERGENCY_SMS_CONTACT")
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
            
            // 保存された状態をクリア
            self.clearSavedAlarmState()
            
            // アラーム停止の通知を送信
            NotificationCenter.default.post(name: .alarmStopped, object: nil)
        }
    }
    
    func stopAlarmSoundOnly() {
        DispatchQueue.main.async {
            // 音のみ停止（成功/失敗はマークしない）
            SoundService.shared.stopAlarmSound()
            print("アラーム音のみ停止（成功/失敗はマークしない）")
            
            // 音が停止されたことを確認
            if !SoundService.shared.isPlaying {
                print("アラーム音の停止が確認されました")
            } else {
                print("警告: アラーム音が停止されていない可能性があります")
                // 再度停止を試行
                SoundService.shared.stopAlarmSound()
            }
            
            // 音が停止されたことを通知（UI更新用）
            NotificationCenter.default.post(name: .alarmSoundStopped, object: nil)
        }
    }
    
    // MARK: - Force Stop Path
    
    func forceStopAlarmWithSuccess() {
        DispatchQueue.main.async {
            print("=== FORCE STOP (DEPRECATED - use centralized state management) ===")
            
            // This method is deprecated - use markSuccessIfValidScan() instead
            // Only allow if in active state
            guard self.alarmState == .active else {
                print("Cannot force stop - alarm not active: \(self.alarmState)")
                return
            }
            
            // Use centralized success handling
            self.markSuccessIfValidScan()
            
            print("=== FORCE STOP COMPLETED (via centralized method) ===")
        }
    }
    
    private func forceStopAudio() {
        print("FORCE STOP: 音声強制停止開始")
        
        // 複数回音声停止を実行
        for i in 1...5 {
            print("FORCE STOP: 音声停止実行 \(i)回目")
            SoundService.shared.stopAlarmSound()
            
            // 少し待機（最後の1回以外）
            if i < 5 {
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        
        // 追加の強制停止（AVAudioPlayerを直接停止）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("FORCE STOP: 追加の音声停止実行")
            SoundService.shared.stopAlarmSound()
        }
        
        // 最終確認
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !SoundService.shared.isPlaying {
                print("✅ FORCE STOP: 音声停止確認完了")
            } else {
                print("⚠️ FORCE STOP: 警告 - 音声が停止されていない可能性があります")
                // 最後の手段として再度停止
                SoundService.shared.stopAlarmSound()
            }
        }
    }
    
    private func forceStopAlarmState() {
        print("FORCE STOP: アラーム状態強制停止")
        
        // 起床成功を記録
        if let alarm = self.currentAlarm, let startTime = self.alarmStartTime {
            let wakeUpTime = Date()
            let timeToWakeUp = wakeUpTime.timeIntervalSince(startTime)
            print("FORCE STOP: 起床成功記録 - \(alarm.title), 時間: \(timeToWakeUp)秒")
        }
        
        // 状態をリセット
        self.isPlaying = false
        self.currentAlarm = nil
        self.alarmStartTime = nil
        
        print("FORCE STOP: アラーム状態リセット完了")
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
        let startTime = Date()
        print("=== QRコード検証開始 ===")
        print("QRコード: \(qrCodeData)")
        print("時刻: \(startTime)")
        print("現在の状態: \(alarmState)")
        print("アラーム再生中: \(isPlaying)")
        print("現在のアラーム: \(currentAlarm?.title ?? "なし")")
        
        // 状態チェック: アクティブ状態でない場合は無効
        guard alarmState == .active else {
            print("❌ QRコード検証失敗: アラームがアクティブ状態ではありません")
            print("   状態: \(alarmState)")
            return false
        }
        
        // 時間制限チェック: アラーム開始から60秒経過している場合は失敗
        if let startTime = alarmStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("経過時間: \(String(format: "%.1f", elapsedTime))秒")
            
            if elapsedTime > 60.0 {
                print("❌ QRコード検証失敗: 60秒の制限時間を超過しました")
                print("   経過時間: \(String(format: "%.1f", elapsedTime))秒")
                
                // 失敗として処理
                handleQRCodeTimeoutFailure()
                return false
            }
        }
        
        // 堅牢なQRコード検証
        let isValid = QRCodeTimerService.shared.validateQRCode(qrCodeData)
        let validationTime = Date().timeIntervalSince(startTime)
        
        print("QRコード検証結果: \(isValid ? "✅ 有効" : "❌ 無効")")
        print("検証時間: \(String(format: "%.3f", validationTime))秒")
        
        if isValid {
            print("=== QRコード有効 ===")
            return true
        } else {
            print("❌ QRコードが無効です")
            return false
        }
    }
    
    public func handleQRCodeTimeoutFailure() {
        print("=== QRコードタイムアウト失敗処理 ===")
        
        // 既に終端状態の場合は処理しない
        guard !alarmState.isTerminalState else {
            print("⚠️ 既に終端状態(\(alarmState))のため、タイムアウト処理をスキップ")
            return
        }
        
        // 状態を失敗に変更
        setAlarmState(.failure)
        
        // 失敗ダイアログを表示
        showFailureDialog()
        
        // 音声を停止
        SoundService.shared.stopAlarmSound()
        
        // QRコードタイマーを停止
        if let alarmId = currentAlarm?.id {
            QRCodeTimerService.shared.stopQRCodeTimer(for: alarmId)
        }
        
        // アラームを停止（失敗として）
        stopCurrentAlarm()
        
        // 失敗通知を送信
        NotificationCenter.default.post(name: .alarmTimeout, object: nil)
        
        // SMS自動送信を実行
        Task {
            await sendTimeoutSMS()
        }
        
        print("=== QRコードタイムアウト失敗処理完了 ===")
    }
    
    private func sendTimeoutSMS() async {
        print("=== SMS自動送信開始 ===")
        
        guard let alarmId = currentAlarm?.id,
              let phoneNumber = getEmergencyPhoneNumber(),
              let startTime = alarmStartTime else {
            print("❌ SMS送信に必要な情報が不足しています")
            print("   アラームID: \(currentAlarm?.id.uuidString ?? "nil")")
            print("   電話番号: \(getEmergencyPhoneNumber() ?? "nil")")
            print("   開始時刻: \(alarmStartTime?.description ?? "nil")")
            
            // フォールバック: 緊急SMS送信を試行
            await sendFallbackSMS()
            return
        }
        
        print("📱 SMS送信準備完了:")
        print("   アラームID: \(alarmId)")
        print("   電話番号: \(phoneNumber)")
        print("   開始時刻: \(startTime)")
        
        // サーバーにタイムアウト通知を送信
        do {
            await ServerWebhookService.shared.notifyTimeout(
                alarmId: alarmId,
                fireDate: startTime,
                phoneNumber: phoneNumber
            )
            print("✅ SMS自動送信完了")
            
            // SMS送信成功を通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .smsSent, object: nil, userInfo: ["success": true])
            }
        } catch {
            print("❌ SMS送信失敗: \(error)")
            print("❌ フォールバックSMS送信を試行")
            await sendFallbackSMS()
            
            // SMS送信失敗を通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .smsSent, object: nil, userInfo: ["success": false])
            }
        }
    }
    
    private func sendFallbackSMS() async {
        print("=== フォールバックSMS送信開始 ===")
        
        // 緊急連絡先が設定されている場合はフォールバックSMS送信を試行
        DispatchQueue.main.async {
            if let phoneNumber = self.getEmergencyPhoneNumber() {
                print("📱 フォールバックSMS送信: \(phoneNumber)")
                
                // SMS送信画面を開く
                let message = "WakeOrPay緊急通知: アラームの停止に失敗しました。"
                let smsURL = "sms:\(phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                
                if let url = URL(string: smsURL) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                        print("✅ SMS送信画面を開きました")
                    } else {
                        print("❌ SMS送信画面を開けませんでした")
                    }
                }
            } else {
                print("❌ 緊急連絡先が設定されていません")
            }
        }
        
        print("=== フォールバックSMS送信完了 ===")
    }
    
    private func performNormalStop() -> Bool {
        print("Normal stop processing (DEPRECATED - use centralized state management)")
        
        // This method is deprecated - use centralized state management instead
        // Only allow if in active state
        guard alarmState == .active else {
            print("Cannot perform normal stop - alarm not active: \(alarmState)")
            return false
        }
        
        // Stop audio
        SoundService.shared.stopAlarmSound()
        
        // Stop QR timer
        if let alarmId = currentAlarm?.id {
            QRCodeTimerService.shared.stopQRCodeTimer(for: alarmId)
        }
        
        // Stop alarm (but don't change state - let centralized methods handle it)
        stopCurrentAlarm()
        
        return true
    }
}

// MARK: - Notification Names

// MARK: - QR Code Timer Service

class QRCodeTimerService: ObservableObject {
    static let shared = QRCodeTimerService()
    
    private var timers: [UUID: Timer] = [:]
    private var alarmIds: [UUID: Date] = [:] // alarmId: 開始時刻
    
    private init() {}
    
    func startQRCodeTimer(for alarmId: UUID, timeoutDuration: TimeInterval = 60.0) {
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
                    
                    // サーバーにタイムアウト通知を送信
                    if let phoneNumber = AlarmService.shared.getEmergencyPhoneNumber(),
                       let startTime = AlarmService.shared.alarmStartTime {
                        Task {
                            await ServerWebhookService.shared.reportTimeout(
                                alarmId: alarmId,
                                fireDate: startTime,
                                phoneNumber: phoneNumber
                            )
                        }
                        print("ServerWebhookService: タイムアウト通知送信完了 - \(alarmId)")
                    }
                }
                
                // SMS緊急通知を送信（クライアント側フォールバック）
                sendEmergencySMS()
                
                // ローカル通知も送信
                sendLocalTimeoutNotification()
                
                // タイムアウト通知を送信
                NotificationCenter.default.post(name: .alarmTimeout, object: nil)
                
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
        print("QRCodeTimerService: QRコード検証開始 - \(qrCodeData)")
        
        // 堅牢なQRコード形式チェック
        guard !qrCodeData.isEmpty else {
            print("QRCodeTimerService: 空のQRコード")
            return false
        }
        
        guard qrCodeData.hasPrefix("WakeOrPay:Stop:") else {
            print("QRCodeTimerService: QRコードの形式が正しくありません: \(qrCodeData)")
            return false
        }
        
        let identifier = String(qrCodeData.dropFirst("WakeOrPay:Stop:".count))
        
        // ユニバーサルQRコードの場合
        if identifier == "Universal" {
            print("QRCodeTimerService: ユニバーサルQRコードを検出")
            
            // アラームがアクティブ状態の場合のみ有効
            guard AlarmService.shared.alarmState == .active else {
                print("QRCodeTimerService: アラームがアクティブ状態ではありません")
                return false
            }
            
            // Universal QRコードの許可設定を確認
            let allowUniversal = true // フラグ: Universal QRコードを常に許可
            
            // 現在のアラームの期待QRコードを確認（存在する場合）
            if allowUniversal || (AlarmService.shared.currentAlarm?.expectedQR == "Universal") {
                print("QRCodeTimerService: 現在のアラームの期待QRコードがUniversalです")
                
                // アラームがアクティブ状態の場合は有効
                print("QRCodeTimerService: ユニバーサルQRコード検証成功")
                // すべてのタイマーを停止
                for alarmId in timers.keys {
                    stopQRCodeTimer(for: alarmId)
                }
                return true
            } else {
                print("QRCodeTimerService: 現在のアラームの期待QRコードはUniversalではありません")
                return false
            }
        }
        
        // 特定のアラームIDの場合（後方互換性のため）
        guard let alarmId = UUID(uuidString: identifier) else {
            print("アラームIDが無効です: \(identifier)")
            return false
        }
        
        // アラームがアクティブ状態の場合のみ有効
        guard AlarmService.shared.alarmState == .active else {
            print("QRCodeTimerService: アラームがアクティブ状態ではありません")
            return false
        }
        
        // 現在のアラームの期待QRコードを確認（存在する場合）
        if let currentAlarm = AlarmService.shared.currentAlarm, currentAlarm.expectedQR == alarmId.uuidString {
            print("QRCodeTimerService: 現在のアラームの期待QRコードが\(alarmId.uuidString)です")
            
            // タイマーが動作中かチェック
            if timers[alarmId] != nil {
                print("QRコード検証成功: \(alarmId)")
                stopQRCodeTimer(for: alarmId)
                return true
            } else {
                print("QRコードは有効ですが、タイマーが動作していません: \(alarmId)")
                return false
            }
        } else {
            print("QRCodeTimerService: 現在のアラームの期待QRコードが\(alarmId.uuidString)ではありません")
            return false
        }
    }
    
    func isTimerRunning(for alarmId: UUID) -> Bool {
        return timers[alarmId] != nil
    }
    
    func getRemainingTime(for alarmId: UUID) -> TimeInterval? {
        guard let startTime = alarmIds[alarmId] else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, 60.0 - elapsed) // 1分 = 60秒
    }
    
    // MARK: - Emergency SMS
    
    private func sendEmergencySMS() {
        // SMSServiceを使用してSMS送信
        DispatchQueue.main.async {
            SMSService.shared.sendEmergencySMS()
        }
    }
    
}

extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
    static let alarmStopped = Notification.Name("alarmStopped")
    static let alarmTimeout = Notification.Name("alarmTimeout")
    static let alarmSoundStopped = Notification.Name("alarmSoundStopped")
    static let qrScanSuccess = Notification.Name("qrScanSuccess")
    static let qrScanTimeout = Notification.Name("qrScanTimeout")
    static let alarmDidSucceed = Notification.Name("alarmDidSucceed")
    static let alarmDidFail = Notification.Name("alarmDidFail")
    static let smsSent = Notification.Name("smsSent")
}
