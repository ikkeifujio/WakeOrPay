//
//  AppColors.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct AppColors {
    
    // MARK: - Primary Colors
    static let primary = Color(red: 0.0, green: 0.5, blue: 1.0) // Blue
    static let primaryDark = Color(red: 0.0, green: 0.4, blue: 0.8)
    static let primaryLight = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    // MARK: - Secondary Colors
    static let secondary = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    static let secondaryDark = Color(red: 0.8, green: 0.5, blue: 0.0)
    static let secondaryLight = Color(red: 1.0, green: 0.7, blue: 0.2)
    
    // MARK: - Status Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.2) // Green
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
    static let error = Color(red: 1.0, green: 0.2, blue: 0.2) // Red
    static let info = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue
    
    // MARK: - Background Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let quaternaryText = Color(.quaternaryLabel)
    
    // MARK: - Separator Colors
    static let separator = Color(.separator)
    static let opaqueSeparator = Color(.opaqueSeparator)
    
    // MARK: - Fill Colors
    static let fill = Color(.systemFill)
    static let secondaryFill = Color(.secondarySystemFill)
    static let tertiaryFill = Color(.tertiarySystemFill)
    static let quaternaryFill = Color(.quaternarySystemFill)
    
    // MARK: - Grouped Background Colors
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    static let tertiaryGroupedBackground = Color(.tertiarySystemGroupedBackground)
    
    // MARK: - Accent Colors
    static let accent = Color.accentColor
    
    // MARK: - Custom Colors
    static let alarmActive = Color(red: 1.0, green: 0.3, blue: 0.3) // Red for active alarms
    static let alarmInactive = Color(red: 0.6, green: 0.6, blue: 0.6) // Gray for inactive alarms
    static let snooze = Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow for snooze
    static let qrCode = Color(red: 0.0, green: 0.0, blue: 0.0) // Black for QR codes
    
    // MARK: - Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [secondary, secondaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [success, Color(red: 0.3, green: 0.9, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [warning, Color(red: 1.0, green: 0.9, blue: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        colors: [error, Color(red: 1.0, green: 0.4, blue: 0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extensions

extension Color {
    static let appPrimary = AppColors.primary
    static let appSecondary = AppColors.secondary
    static let appSuccess = AppColors.success
    static let appWarning = AppColors.warning
    static let appError = AppColors.error
    static let appInfo = AppColors.info
    static let appBackground = AppColors.background
    static let appSecondaryBackground = AppColors.secondaryBackground
    static let appText = AppColors.text
    static let appSecondaryText = AppColors.secondaryText
    static let appAlarmActive = AppColors.alarmActive
    static let appAlarmInactive = AppColors.alarmInactive
    static let appSnooze = AppColors.snooze
    static let appQRCode = AppColors.qrCode
}

// MARK: - Dynamic Colors

extension AppColors {
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // Dark mode aware colors
    static let adaptiveText = dynamicColor(
        light: Color.black,
        dark: Color.white
    )
    
    static let adaptiveBackground = dynamicColor(
        light: Color.white,
        dark: Color.black
    )
    
    static let adaptiveSecondaryBackground = dynamicColor(
        light: Color(red: 0.95, green: 0.95, blue: 0.95),
        dark: Color(red: 0.1, green: 0.1, blue: 0.1)
    )
}
