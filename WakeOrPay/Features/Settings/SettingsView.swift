//
//  SettingsView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                
                List {
                    // 基本設定
                    basicSettingsSection
                    
                    // 音声設定
                    soundSettingsSection
                    
                    // スヌーズ設定
                    snoozeSettingsSection
                    
                    // QRコード設定
                    qrCodeSettingsSection
                    
                    // その他の設定
                    otherSettingsSection
                    
                    // アプリ情報
                    appInfoSection
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("設定をリセット", isPresented: $viewModel.showingResetAlert) {
                Button("リセット", role: .destructive) {
                    viewModel.resetToDefault()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("すべての設定をデフォルトに戻しますか？")
            }
            .sheet(isPresented: $viewModel.showingAbout) {
                AboutView()
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Basic Settings Section
    
    private var basicSettingsSection: some View {
        Section("基本設定") {
            HStack {
                Text("デフォルト音声")
                    .font(AppConstants.Fonts.body)
                
                Spacer()
                
                Text(viewModel.soundDisplayName)
                    .font(AppConstants.Fonts.body)
                    .foregroundColor(AppConstants.Colors.secondaryText)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 音声選択シートを表示
            }
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                HStack {
                    Text("デフォルト音量")
                        .font(AppConstants.Fonts.body)
                    
                    Spacer()
                    
                    Text("\(viewModel.volumePercentage)%")
                        .font(AppConstants.Fonts.body)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                
                Slider(value: $viewModel.settings.defaultVolume, in: 0...1, step: 0.1)
                    .accentColor(AppConstants.Colors.primary)
            }
        }
    }
    
    // MARK: - Sound Settings Section
    
    private var soundSettingsSection: some View {
        Section("音声設定") {
            Toggle("バイブレーション", isOn: $viewModel.settings.hapticFeedback)
                .font(AppConstants.Fonts.body)
            
            Toggle("バックグラウンド再生", isOn: $viewModel.settings.backgroundMode)
                .font(AppConstants.Fonts.body)
        }
    }
    
    // MARK: - Snooze Settings Section
    
    private var snoozeSettingsSection: some View {
        Section("スヌーズ設定") {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                HStack {
                    Text("デフォルトスヌーズ間隔")
                        .font(AppConstants.Fonts.body)
                    
                    Spacer()
                    
                    Text("\(viewModel.settings.defaultSnoozeInterval)分")
                        .font(AppConstants.Fonts.body)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                
                Slider(value: Binding(
                    get: { Float(viewModel.settings.defaultSnoozeInterval) },
                    set: { viewModel.updateDefaultSnoozeInterval(Int($0)) }
                ), in: 1...60, step: 1)
                .accentColor(AppConstants.Colors.primary)
            }
            
            Toggle("自動スヌーズ", isOn: $viewModel.settings.autoSnooze)
                .font(AppConstants.Fonts.body)
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                HStack {
                    Text("最大スヌーズ回数")
                        .font(AppConstants.Fonts.body)
                    
                    Spacer()
                    
                    Text("\(viewModel.settings.maxSnoozeCount)回")
                        .font(AppConstants.Fonts.body)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                
                Slider(value: Binding(
                    get: { Float(viewModel.settings.maxSnoozeCount) },
                    set: { viewModel.updateMaxSnoozeCount(Int($0)) }
                ), in: 1...10, step: 1)
                .accentColor(AppConstants.Colors.primary)
            }
        }
    }
    
    // MARK: - QR Code Settings Section
    
    private var qrCodeSettingsSection: some View {
        Section("QRコード設定") {
            Toggle("QRコード機能を有効にする", isOn: $viewModel.settings.qrCodeEnabled)
                .font(AppConstants.Fonts.body)
            
            if viewModel.settings.qrCodeEnabled {
                Text("アラーム停止にQRコードのスキャンが必要になります")
                    .font(AppConstants.Fonts.caption)
                    .foregroundColor(AppConstants.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Other Settings Section
    
    private var otherSettingsSection: some View {
        Section("その他") {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                HStack {
                    Text("アラーム継続時間")
                        .font(AppConstants.Fonts.body)
                    
                    Spacer()
                    
                    Text(viewModel.alarmDurationDisplayName)
                        .font(AppConstants.Fonts.body)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                
                Picker("アラーム継続時間", selection: $viewModel.settings.alarmDuration) {
                    ForEach(viewModel.alarmDurationOptions, id: \.0) { duration, name in
                        Text(name).tag(duration)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Button("設定をリセット") {
                viewModel.showResetConfirmation()
            }
            .font(AppConstants.Fonts.body)
            .foregroundColor(AppConstants.Colors.error)
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section("アプリ情報") {
            HStack {
                Text("バージョン")
                    .font(AppConstants.Fonts.body)
                
                Spacer()
                
                Text(viewModel.appVersion)
                    .font(AppConstants.Fonts.body)
                    .foregroundColor(AppConstants.Colors.secondaryText)
            }
            
            Button("このアプリについて") {
                viewModel.showAbout()
            }
            .font(AppConstants.Fonts.body)
            .foregroundColor(AppConstants.Colors.primary)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.Spacing.lg) {
                // アプリアイコン
                Image(systemName: "alarm.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppConstants.Colors.primary)
                
                // アプリ名
                Text(AppConstants.appName)
                    .font(AppConstants.Fonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppConstants.Colors.text)
                
                // バージョン
                Text("バージョン \(AppConstants.appVersion)")
                    .font(AppConstants.Fonts.body)
                    .foregroundColor(AppConstants.Colors.secondaryText)
                
                // 説明
                VStack(spacing: AppConstants.Spacing.md) {
                    Text("面倒（早起き）を楽しくに変えるアラームアプリ")
                        .font(AppConstants.Fonts.body)
                        .foregroundColor(AppConstants.Colors.text)
                        .multilineTextAlignment(.center)
                    
                    Text("QRコードスキャンやスヌーズ機能で、確実に起きられるアラームを提供します。")
                        .font(AppConstants.Fonts.caption)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 機能一覧
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("主な機能")
                        .font(AppConstants.Fonts.headline)
                        .foregroundColor(AppConstants.Colors.text)
                    
                    FeatureRowView(icon: "alarm", title: "カスタマイズ可能なアラーム")
                    FeatureRowView(icon: "repeat", title: "曜日指定のリピート機能")
                    FeatureRowView(icon: "snooze", title: "スヌーズ機能")
                    FeatureRowView(icon: "qrcode", title: "QRコードでの停止機能")
                    FeatureRowView(icon: "speaker.wave.2", title: "多様な音声選択")
                    FeatureRowView(icon: "hand.tap", title: "バイブレーション対応")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(AppConstants.Spacing.lg)
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row View

struct FeatureRowView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 20)
            
            Text(title)
                .font(AppConstants.Fonts.body)
                .foregroundColor(AppConstants.Colors.text)
        }
    }
}

#Preview {
    SettingsView()
}
