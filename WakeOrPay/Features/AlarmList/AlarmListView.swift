//
//  AlarmListView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmListViewModel()
    @State private var showingSettings = false
    @State private var sortType: SortType = .time
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .font(AppConstants.Fonts.body)
                } else if viewModel.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListView
                }
            }
            .navigationTitle("WakeOrPay")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("設定") {
                        showingSettings = true
                    }
                    .foregroundColor(AppConstants.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddAlarm) {
                        Image(systemName: "plus")
                            .foregroundColor(AppConstants.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddAlarm) {
                AddAlarmView { alarm in
                    viewModel.addAlarm(alarm)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            Task {
                await viewModel.requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundColor(AppConstants.Colors.secondary)
            
            Text("アラームがありません")
                .font(AppConstants.Fonts.title2)
                .foregroundColor(AppConstants.Colors.text)
            
            Text("右上の + ボタンから\nアラームを追加してください")
                .font(AppConstants.Fonts.body)
                .foregroundColor(AppConstants.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("アラームを追加") {
                viewModel.showAddAlarm()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(AppConstants.Spacing.lg)
    }
    
    // MARK: - Alarm List
    
    private var alarmListView: some View {
        VStack(spacing: 0) {
            // 次のアラーム表示
            if let nextAlarm = viewModel.nextAlarm {
                nextAlarmCard(nextAlarm)
            }
            
            // ソート選択
            sortPicker
            
            // アラーム一覧
            List {
                ForEach(viewModel.alarms) { alarm in
                    AlarmRowView(alarm: alarm) {
                        viewModel.selectAlarm(alarm)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("削除", role: .destructive) {
                            viewModel.deleteAlarm(alarm)
                        }
                        
                        Button("複製") {
                            viewModel.duplicateAlarm(alarm)
                        }
                        .tint(AppConstants.Colors.secondary)
                    }
                }
                .onDelete(perform: viewModel.deleteAlarm)
            }
            .listStyle(PlainListStyle())
        }
        .sheet(item: $viewModel.selectedAlarm) { alarm in
            AlarmDetailView(alarm: alarm)
        }
    }
    
    // MARK: - Next Alarm Card
    
    private func nextAlarmCard(_ alarm: Alarm) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("次のアラーム")
                    .font(AppConstants.Fonts.headline)
                    .foregroundColor(AppConstants.Colors.text)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.title)
                        .font(AppConstants.Fonts.title2)
                        .foregroundColor(AppConstants.Colors.text)
                    
                    Text(alarm.timeString)
                        .font(AppConstants.Fonts.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppConstants.Colors.primary)
                    
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatString)
                            .font(AppConstants.Fonts.caption)
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: { viewModel.toggleAlarm(alarm) }) {
                    Image(systemName: alarm.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(alarm.isEnabled ? AppConstants.Colors.warning : AppConstants.Colors.success)
                }
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(AppConstants.Colors.secondaryBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .padding(.horizontal, AppConstants.Spacing.md)
        .padding(.top, AppConstants.Spacing.sm)
    }
    
    // MARK: - Sort Picker
    
    private var sortPicker: some View {
        Picker("ソート", selection: $sortType) {
            ForEach(SortType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, AppConstants.Spacing.md)
        .padding(.vertical, AppConstants.Spacing.sm)
        .onChange(of: sortType) { newType in
            viewModel.sortAlarms(by: newType)
        }
    }
}

// MARK: - Alarm Row View

struct AlarmRowView: View {
    let alarm: Alarm
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.title)
                        .font(AppConstants.Fonts.headline)
                        .foregroundColor(AppConstants.Colors.text)
                        .lineLimit(1)
                    
                    Text(alarm.timeString)
                        .font(AppConstants.Fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.Colors.primary)
                    
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatString)
                            .font(AppConstants.Fonts.caption)
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(alarm.isEnabled))
                    .labelsHidden()
                    .disabled(true)
            }
            .padding(.vertical, AppConstants.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppConstants.Fonts.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.md)
            .background(AppConstants.Colors.primary)
            .cornerRadius(AppConstants.UI.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppConstants.Animation.easeInOut, value: configuration.isPressed)
    }
}

#Preview {
    AlarmListView()
}
