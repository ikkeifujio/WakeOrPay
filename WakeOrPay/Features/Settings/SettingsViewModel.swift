//
//  SettingsViewModel.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AlarmSettings
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showingResetAlert: Bool = false
    @Published var showingAbout: Bool = false
    
    private let appSettings = AppSettings()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.settings = appSettings.alarmSettings
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        appSettings.$alarmSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Management
    
    func updateSettings() {
        isSaving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.appSettings.alarmSettings = self.settings
            self.isSaving = false
        }
    }
    
    func resetToDefault() {
        settings = AlarmSettings.default
        updateSettings()
        showingResetAlert = false
    }
    
    func showResetConfirmation() {
        showingResetAlert = true
    }
    
    func hideResetConfirmation() {
        showingResetAlert = false
    }
    
    // MARK: - UI Actions
    
    func showAbout() {
        showingAbout = true
    }
    
    func hideAbout() {
        showingAbout = false
    }
    
    // MARK: - Settings Updates
    
    func updateDefaultSound(_ soundName: String) {
        settings.defaultSoundName = soundName
        updateSettings()
    }
    
    func updateDefaultVolume(_ volume: Float) {
        settings.defaultVolume = max(0.0, min(1.0, volume))
        updateSettings()
    }
    
    func updateDefaultSnoozeInterval(_ interval: Int) {
        settings.defaultSnoozeInterval = max(1, min(60, interval))
        updateSettings()
    }
    
    
    func updateHapticFeedback(_ enabled: Bool) {
        settings.hapticFeedback = enabled
        updateSettings()
    }
    
    func updateAutoSnooze(_ enabled: Bool) {
        settings.autoSnooze = enabled
        updateSettings()
    }
    
    func updateMaxSnoozeCount(_ count: Int) {
        settings.maxSnoozeCount = max(1, min(10, count))
        updateSettings()
    }
    
    func updateAlarmDuration(_ duration: Int) {
        settings.alarmDuration = max(60, min(1800, duration)) // 1分〜30分
        updateSettings()
    }
    
    func updateBackgroundMode(_ enabled: Bool) {
        settings.backgroundMode = enabled
        updateSettings()
    }
    
    func updateCountdownEnabled(_ enabled: Bool) {
        settings.countdownEnabled = enabled
        updateSettings()
    }
    
    // MARK: - Computed Properties
    
    var availableSounds: [(String, String)] {
        SoundService.availableSounds.map { ($0.key, $0.value) }
    }
    
    var soundDisplayName: String {
        SoundService.availableSounds[settings.defaultSoundName] ?? settings.defaultSoundName
    }
    
    var volumePercentage: Int {
        Int(settings.defaultVolume * 100)
    }
    
    var snoozeIntervalOptions: [Int] {
        Array(1...60).filter { $0 % 5 == 0 || $0 <= 10 }
    }
    
    var maxSnoozeCountOptions: [Int] {
        Array(1...10)
    }
    
    var alarmDurationOptions: [(Int, String)] {
        [
            (60, "1分"),
            (120, "2分"),
            (300, "5分"),
            (600, "10分"),
            (900, "15分"),
            (1800, "30分")
        ]
    }
    
    var alarmDurationDisplayName: String {
        alarmDurationOptions.first { $0.0 == settings.alarmDuration }?.1 ?? "5分"
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - App Information
    
    var appVersion: String {
        AppConstants.appVersion
    }
    
    var appName: String {
        AppConstants.appName
    }
    
    // MARK: - Validation
    
    func validateSettings() -> Bool {
        if settings.defaultVolume < 0.0 || settings.defaultVolume > 1.0 {
            errorMessage = "音量は0.0〜1.0の間で設定してください"
            return false
        }
        
        if settings.defaultSnoozeInterval < 1 || settings.defaultSnoozeInterval > 60 {
            errorMessage = "スヌーズ間隔は1-60分の間で設定してください"
            return false
        }
        
        if settings.maxSnoozeCount < 1 || settings.maxSnoozeCount > 10 {
            errorMessage = "最大スヌーズ回数は1-10回の間で設定してください"
            return false
        }
        
        if settings.alarmDuration < 60 || settings.alarmDuration > 1800 {
            errorMessage = "アラーム継続時間は1-30分の間で設定してください"
            return false
        }
        
        clearError()
        return true
    }
}
