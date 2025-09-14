//
//  AppConstants.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import SwiftUI
import UIKit

struct AppConstants {
    
    // MARK: - App Information
    static let appName = "WakeOrPay"
    static let appVersion = "1.0.0"
    static let bundleIdentifier = "com.ikkei.WakeOrPay"
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let alarms = "WakeOrPayAlarms"
        static let settings = "WakeOrPaySettings"
        static let firstLaunch = "WakeOrPayFirstLaunch"
        static let notificationPermissionRequested = "WakeOrPayNotificationPermissionRequested"
    }
    
    // MARK: - Notification Identifiers
    struct NotificationIdentifiers {
        static let alarmCategory = "ALARM_CATEGORY"
        static let snoozeAction = "SNOOZE_ACTION"
        static let stopAction = "STOP_ACTION"
    }
    
    // MARK: - Default Values
    struct DefaultValues {
        static let snoozeInterval = 5 // minutes
        static let maxSnoozeCount = 3
        static let alarmDuration = 300 // seconds (5 minutes)
        static let defaultVolume: Float = 0.8
        static let defaultSoundName = "default"
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Double = 0.1
        static let animationDuration: Double = 0.3
        static let hapticFeedbackDelay: Double = 0.1
    }
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.orange
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.medium)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let linear = SwiftUI.Animation.linear(duration: 0.2)
    }
    
    // MARK: - Sound Files
    struct SoundFiles {
        static let defaultSound = "default.wav"
        static let bellSound = "bell.wav"
        static let chimeSound = "chime.wav"
        static let gentleSound = "gentle.wav"
        static let energeticSound = "energetic.wav"
        static let natureSound = "nature.wav"
    }
    
    // MARK: - QR Code
    struct QRCode {
        static let defaultData = "WakeOrPay:AlarmStop"
        static let dataPrefix = "WakeOrPay:"
    }
    
    // MARK: - Time Formats
    struct TimeFormat {
        static let time = "HH:mm"
        static let dateTime = "yyyy/MM/dd HH:mm"
        static let date = "yyyy/MM/dd"
        static let timeWithSeconds = "HH:mm:ss"
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let alarmList = "アラーム一覧"
        static let addAlarm = "アラームを追加"
        static let alarmToggle = "アラームのオン/オフ"
        static let alarmTime = "アラーム時刻"
        static let alarmTitle = "アラームタイトル"
        static let snoozeButton = "スヌーズ"
        static let stopButton = "停止"
    }
}
