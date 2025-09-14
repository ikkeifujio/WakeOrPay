//
//  AlarmSettings.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation

struct AlarmSettings: Codable {
    var defaultSoundName: String
    var defaultVolume: Float
    var defaultSnoozeInterval: Int
    var qrCodeEnabled: Bool
    var hapticFeedback: Bool
    var autoSnooze: Bool
    var maxSnoozeCount: Int
    var alarmDuration: Int // seconds
    var backgroundMode: Bool
    
    init(
        defaultSoundName: String = "default",
        defaultVolume: Float = 0.8,
        defaultSnoozeInterval: Int = 5,
        qrCodeEnabled: Bool = false,
        hapticFeedback: Bool = true,
        autoSnooze: Bool = false,
        maxSnoozeCount: Int = 3,
        alarmDuration: Int = 300, // 5 minutes
        backgroundMode: Bool = true
    ) {
        self.defaultSoundName = defaultSoundName
        self.defaultVolume = defaultVolume
        self.defaultSnoozeInterval = defaultSnoozeInterval
        self.qrCodeEnabled = qrCodeEnabled
        self.hapticFeedback = hapticFeedback
        self.autoSnooze = autoSnooze
        self.maxSnoozeCount = maxSnoozeCount
        self.alarmDuration = alarmDuration
        self.backgroundMode = backgroundMode
    }
    
    static let `default` = AlarmSettings()
}

// アプリ全体の設定を管理
class AppSettings: ObservableObject {
    @Published var alarmSettings: AlarmSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let settingsKey = "WakeOrPaySettings"
    
    init() {
        self.alarmSettings = Self.loadSettings()
    }
    
    private static func loadSettings() -> AlarmSettings {
        guard let data = UserDefaults.standard.data(forKey: "WakeOrPaySettings"),
              let settings = try? JSONDecoder().decode(AlarmSettings.self, from: data) else {
            return AlarmSettings.default
        }
        return settings
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(alarmSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    func resetToDefault() {
        alarmSettings = AlarmSettings.default
    }
}
