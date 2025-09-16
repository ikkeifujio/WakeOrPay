//
//  AddAlarmView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AlarmDetailViewModel(alarm: Alarm())
    
    let onSave: (Alarm) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppConstants.Spacing.lg) {
                        // タイトル入力
                        titleSection
                        
                        // 時刻設定
                        timeSection
                        
                        // リピート設定
                        repeatSection
                        
                        // 音声設定
                        soundSection
                        
                        // スヌーズ設定
                        snoozeSection
                        
                    }
                    .padding(AppConstants.Spacing.md)
                }
            }
            .navigationTitle("アラームを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAlarm()
                    }
                    .disabled(viewModel.isSaving)
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
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("タイトル")
                .font(AppConstants.Fonts.headline)
                .foregroundColor(AppConstants.Colors.text)
            
            TextField("アラームのタイトル", text: $viewModel.editedTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(AppConstants.Fonts.body)
        }
    }
    
    
    private var timeSection: some View {
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
    }
    
    
    private var repeatSection: some View {
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
    }
    
    
    private var soundSection: some View {
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
    }
    
    
    private var snoozeSection: some View {
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
    
    
    
    private func saveAlarm() {
        guard viewModel.validateInput() else { return }
        
        let newAlarm = Alarm(
            title: viewModel.editedTitle,
            time: viewModel.editedTime,
            isEnabled: true,
            repeatDays: viewModel.editedRepeatDays,
            soundName: viewModel.editedSoundName,
            volume: viewModel.editedVolume,
            snoozeEnabled: viewModel.editedSnoozeEnabled,
            snoozeInterval: viewModel.editedSnoozeInterval,
            qrCodeRequired: true
        )
        
        onSave(newAlarm)
        dismiss()
    }
}


struct TimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("時刻", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("時刻を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}


struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSound: String
    
    private let sounds = SoundService.availableSounds
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sounds.map { $0.key }, id: \.self) { soundKey in
                    HStack {
                        Text(sounds[soundKey] ?? soundKey)
                            .font(AppConstants.Fonts.body)
                        
                        Spacer()
                        
                        if selectedSound == soundKey {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppConstants.Colors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSound = soundKey
                    }
                }
            }
            .navigationTitle("音声を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Repeat Picker View

struct RepeatPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    HStack {
                        Text(weekday.name)
                            .font(AppConstants.Fonts.body)
                        
                        Spacer()
                        
                        if selectedDays.contains(weekday) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppConstants.Colors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDays.contains(weekday) {
                            selectedDays.remove(weekday)
                        } else {
                            selectedDays.insert(weekday)
                        }
                    }
                }
            }
            .navigationTitle("リピートを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddAlarmView { _ in }
}
