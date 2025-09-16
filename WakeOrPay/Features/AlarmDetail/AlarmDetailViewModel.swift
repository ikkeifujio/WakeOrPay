//
//  AlarmDetailViewModel.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//
import UIKit
import Foundation
import Combine

class AlarmDetailViewModel: ObservableObject {
    @Published var alarm: Alarm
    @Published var isEditing: Bool = false
    @Published var showingTimePicker: Bool = false
    @Published var showingSoundPicker: Bool = false
    @Published var showingRepeatPicker: Bool = false
    @Published var showingQRCode: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving: Bool = false
    
    // 編集用のプロパティ
    @Published var editedTitle: String = ""
    @Published var editedTime: Date = Date()
    @Published var editedRepeatDays: Set<Weekday> = []
    @Published var editedSoundName: String = "default"
    @Published var editedVolume: Float = 0.8
    @Published var editedSnoozeEnabled: Bool = true
    @Published var editedSnoozeInterval: Int = 5
    
    private let alarmService = AlarmService.shared
    private let soundService = SoundService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(alarm: Alarm) {
        self.alarm = alarm
        setupEditingProperties()
    }
    
    // MARK: - Setup
    
    private func setupEditingProperties() {
        editedTitle = alarm.title
        editedTime = alarm.time
        editedRepeatDays = alarm.repeatDays
        editedSoundName = alarm.soundName
        editedVolume = alarm.volume
        editedSnoozeEnabled = alarm.snoozeEnabled
        editedSnoozeInterval = alarm.snoozeInterval
    }
    
    // MARK: - Actions
    
    func startEditing() {
        isEditing = true
        setupEditingProperties()
    }
    
    func cancelEditing() {
        isEditing = false
        setupEditingProperties()
        clearError()
    }
    
    func saveChanges() {
        guard validateInput() else { return }
        
        isSaving = true
        
        var updatedAlarm = alarm
        updatedAlarm.title = editedTitle
        updatedAlarm.time = editedTime
        updatedAlarm.repeatDays = editedRepeatDays
        updatedAlarm.soundName = editedSoundName
        updatedAlarm.volume = editedVolume
        updatedAlarm.snoozeEnabled = editedSnoozeEnabled
        updatedAlarm.snoozeInterval = editedSnoozeInterval
        updatedAlarm.qrCodeRequired = true
        updatedAlarm.updatedAt = Date()
        
        alarmService.updateAlarm(updatedAlarm)
        alarm = updatedAlarm
        isEditing = false
        isSaving = false
    }
    
    func deleteAlarm() {
        alarmService.deleteAlarm(alarm)
    }
    
    func toggleAlarm() {
        alarmService.toggleAlarm(alarm)
    }
    
    // MARK: - Validation
    
    func validateInput() -> Bool {
        if editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "タイトルを入力してください"
            return false
        }
        
        if editedTitle.count > 50 {
            errorMessage = "タイトルは50文字以内で入力してください"
            return false
        }
        
        if editedSnoozeInterval < 1 || editedSnoozeInterval > 60 {
            errorMessage = "スヌーズ間隔は1-60分の間で設定してください"
            return false
        }
        
        clearError()
        return true
    }
    
    // MARK: - UI Actions
    
    func showTimePicker() {
        showingTimePicker = true
    }
    
    func hideTimePicker() {
        showingTimePicker = false
    }
    
    func showSoundPicker() {
        showingSoundPicker = true
    }
    
    func hideSoundPicker() {
        showingSoundPicker = false
    }
    
    func showRepeatPicker() {
        showingRepeatPicker = true
    }
    
    func hideRepeatPicker() {
        showingRepeatPicker = false
    }
    
    func showQRCode() {
        showingQRCode = true
    }
    
    func hideQRCode() {
        showingQRCode = false
    }
    
    // MARK: - Sound Testing
    
    func testSound() {
        soundService.playAlarmSound(editedSoundName, volume: editedVolume)
        
        // 3秒後に停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.soundService.stopAlarmSound()
        }
    }
    
    // MARK: - Computed Properties
    
    var timeString: String {
        DateUtils.formatTime(editedTime)
    }
    
    var repeatString: String {
        if editedRepeatDays.isEmpty {
            return "一度だけ"
        }
        
        let sortedDays = editedRepeatDays.sorted { $0.rawValue < $1.rawValue }
        let dayNames = sortedDays.map { $0.shortName }
        return dayNames.joined(separator: ", ")
    }
    
    var soundDisplayName: String {
        SoundService.availableSounds[editedSoundName] ?? editedSoundName
    }
    
    var nextAlarmTime: Date? {
        var tempAlarm = alarm
        tempAlarm.time = editedTime
        tempAlarm.repeatDays = editedRepeatDays
        return tempAlarm.nextAlarmTime()
    }
    
    var nextAlarmTimeString: String {
        guard let nextTime = nextAlarmTime else { return "設定されていません" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: nextTime)
    }
    
    var qrCodeImage: UIImage? {
        QRCodeUtils.generateAlarmStopQRCode()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Repeat Day Management
    
    func toggleRepeatDay(_ weekday: Weekday) {
        if editedRepeatDays.contains(weekday) {
            editedRepeatDays.remove(weekday)
        } else {
            editedRepeatDays.insert(weekday)
        }
    }
    
    func isRepeatDaySelected(_ weekday: Weekday) -> Bool {
        editedRepeatDays.contains(weekday)
    }
    
    // MARK: - Volume Control
    
    func updateVolume(_ volume: Float) {
        editedVolume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Snooze Interval
    
    func updateSnoozeInterval(_ interval: Int) {
        editedSnoozeInterval = max(1, min(60, interval))
    }
}
