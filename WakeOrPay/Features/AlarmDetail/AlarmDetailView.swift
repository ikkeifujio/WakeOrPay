//
//  AlarmDetailView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AlarmDetailViewModel
    @State private var showingDeleteAlert = false
    
    init(alarm: Alarm) {
        self._viewModel = StateObject(wrappedValue: AlarmDetailViewModel(alarm: alarm))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppConstants.Spacing.lg) {
                        // アラーム情報
                        alarmInfoSection
                        
                        // 編集フォーム
                        if viewModel.isEditing {
                            editingForm
                        }
                        
                        // 次のアラーム時刻
                        nextAlarmSection
                        
                        // QRコード表示
                        if viewModel.alarm.qrCodeRequired {
                            qrCodeSection
                        }
                    }
                    .padding(AppConstants.Spacing.md)
                }
            }
            .navigationTitle(viewModel.alarm.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if viewModel.isEditing {
                            Button("キャンセル") {
                                viewModel.cancelEditing()
                            }
                            
                            Button("保存") {
                                viewModel.saveChanges()
                            }
                            .disabled(viewModel.isSaving)
                        } else {
                            Button("編集") {
                                viewModel.startEditing()
                            }
                            
                            Menu {
                                Button("複製") {
                                    // 複製処理
                                }
                                
                                Button("削除", role: .destructive) {
                                    showingDeleteAlert = true
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingTimePicker) {
                TimePickerView(selectedTime: $viewModel.editedTime)
            }
            .sheet(isPresented: $viewModel.showingSoundPicker) {
                SoundPickerView(selectedSound: $viewModel.editedSoundName)
            }
            .sheet(isPresented: $viewModel.showingRepeatPicker) {
                RepeatPickerView(selectedDays: $viewModel.editedRepeatDays)
            }
            // .sheet(isPresented: $viewModel.showingQRCode) {
            //     QRCodeDisplayView(qrImage: viewModel.qrCodeImage)
            // }
            .alert("アラームを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    viewModel.deleteAlarm()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("このアラームを削除しますか？この操作は取り消せません。")
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
    
    // MARK: - Alarm Info Section
    
    private var alarmInfoSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            // 時刻表示
            Text(viewModel.alarm.timeString)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(AppConstants.Colors.primary)
            
            // タイトル
            Text(viewModel.alarm.title)
                .font(AppConstants.Fonts.title2)
                .foregroundColor(AppConstants.Colors.text)
                .multilineTextAlignment(.center)
            
            // リピート情報
            if !viewModel.alarm.repeatDays.isEmpty {
                Text(viewModel.alarm.repeatString)
                    .font(AppConstants.Fonts.body)
                    .foregroundColor(AppConstants.Colors.secondaryText)
            }
            
            // 有効/無効状態
            HStack {
                Image(systemName: viewModel.alarm.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.alarm.isEnabled ? AppConstants.Colors.success : AppConstants.Colors.error)
                
                Text(viewModel.alarm.isEnabled ? "有効" : "無効")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(viewModel.alarm.isEnabled ? AppConstants.Colors.success : AppConstants.Colors.error)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(AppConstants.Colors.secondaryBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
    }
    
    // MARK: - Editing Form
    
    private var editingForm: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // タイトル編集
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Text("タイトル")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                TextField("アラームのタイトル", text: $viewModel.editedTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(AppConstants.Fonts.body)
            }
            
            // 時刻編集
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Text("時刻")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                Button(action: viewModel.showTimePicker) {
                    HStack {
                        Text(viewModel.timeString)
                            .font(AppConstants.Fonts.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppConstants.Colors.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                    .padding(AppConstants.Spacing.md)
                    .background(AppConstants.Colors.secondaryBackground)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // リピート編集
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Text("リピート")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                Button(action: viewModel.showRepeatPicker) {
                    HStack {
                        Text(viewModel.repeatString)
                            .font(AppConstants.Fonts.body)
                            .foregroundColor(AppConstants.Colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                    .padding(AppConstants.Spacing.md)
                    .background(AppConstants.Colors.secondaryBackground)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 音声編集
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Text("音声")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                Button(action: viewModel.showSoundPicker) {
                    HStack {
                        Text(viewModel.soundDisplayName)
                            .font(AppConstants.Fonts.body)
                            .foregroundColor(AppConstants.Colors.text)
                        
                        Spacer()
                        
                        Button("テスト") {
                            viewModel.testSound()
                        }
                        .font(AppConstants.Fonts.caption)
                        .foregroundColor(AppConstants.Colors.primary)
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                    .padding(AppConstants.Spacing.md)
                    .background(AppConstants.Colors.secondaryBackground)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 音量スライダー
                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text("音量: \(Int(viewModel.editedVolume * 100))%")
                        .font(AppConstants.Fonts.caption)
                        .foregroundColor(AppConstants.Colors.secondaryText)
                    
                    Slider(value: $viewModel.editedVolume, in: 0...1, step: 0.1)
                        .accentColor(AppConstants.Colors.primary)
                }
                .padding(.top, AppConstants.Spacing.xs)
            }
            
            // スヌーズ編集
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Toggle("スヌーズを有効にする", isOn: $viewModel.editedSnoozeEnabled)
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                if viewModel.editedSnoozeEnabled {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                        Text("スヌーズ間隔: \(viewModel.editedSnoozeInterval)分")
                            .font(AppConstants.Fonts.caption)
                            .foregroundColor(AppConstants.Colors.secondaryText)
                        
                        Slider(value: Binding(
                            get: { Float(viewModel.editedSnoozeInterval) },
                            set: { viewModel.updateSnoozeInterval(Int($0)) }
                        ), in: 1...60, step: 1)
                        .accentColor(AppConstants.Colors.primary)
                    }
                    .padding(.top, AppConstants.Spacing.xs)
                }
            }
            
        }
        .padding(AppConstants.Spacing.md)
        .background(AppConstants.Colors.secondaryBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
    }
    
    // MARK: - Next Alarm Section
    
    private var nextAlarmSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("次のアラーム")
                .font(AppConstants.Fonts.headline)
                .foregroundColor(AppConstants.Colors.text)
            
            Text(viewModel.nextAlarmTimeString)
                .font(AppConstants.Fonts.title2)
                .foregroundColor(AppConstants.Colors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.md)
        .background(AppConstants.Colors.secondaryBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
    }
    
    // MARK: - QR Code Section
    
    private var qrCodeSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Text("QRコード")
                .font(AppConstants.Fonts.headline)
                .foregroundColor(AppConstants.Colors.text)
            
            if let qrImage = viewModel.qrCodeImage {
                Image(uiImage: qrImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(AppConstants.UI.cornerRadius)
            }
            
            Text("このQRコードをスキャンしてアラームを停止できます")
                .font(AppConstants.Fonts.caption)
                .foregroundColor(AppConstants.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(AppConstants.Spacing.md)
        .background(AppConstants.Colors.secondaryBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
    }
}


#Preview {
    AlarmDetailView(alarm: Alarm(title: "テストアラーム", time: Date()))
}
