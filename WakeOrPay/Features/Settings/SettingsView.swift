//
//  SettingsView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit
import MessageUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingMailComposer = false
    @State private var showingSMSSettings = false
    
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
                    
                    
                    // 緊急通知設定
                    emergencyNotificationSection
                    
                    
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
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView()
            }
            .sheet(isPresented: $showingSMSSettings) {
                SMSSettingsView()
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
            
            Toggle("カウントダウン機能", isOn: $viewModel.settings.countdownEnabled)
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
    
    
    // MARK: - Emergency Notification Section
    
    private var emergencyNotificationSection: some View {
        Section("緊急通知設定") {
            // SMS通知設定
            HStack {
                Text("SMS通知")
                    .font(.body)
                
                Spacer()
                
                if SMSService.shared.canSendSMS() {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            Button("SMS設定") {
                showingSMSSettings = true
            }
            .font(.body)
            .foregroundColor(.blue)
            .disabled(!SMSService.shared.canSendSMS())
            
            Button("SMSテスト") {
                SMSService.shared.sendTestSMS()
            }
            .font(.body)
            .foregroundColor(.blue)
            .disabled(!SMSService.shared.canSendSMS())
            
            Text("QRコードスキャンが1分以内に完了しない場合、設定した連絡先にSMSを自動送信します")
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Mail Composer View

struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["emergency@example.com"]) // 実際の緊急連絡先に変更
        composer.setSubject("WakeOrPay 緊急通知テスト")
        composer.setMessageBody("これはWakeOrPayアプリからの緊急通知テストです。\n\nQRコードスキャンがタイムアウトしました。", isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}


// MARK: - SMS Settings View

struct SMSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber: String = ""
    @State private var message: String = ""
    @State private var useServerSMS: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("SMS送信方法") {
                    Toggle("サーバー自動送信を使用", isOn: $useServerSMS)
                    
                    Text(useServerSMS ? 
                         "サーバーが自動的にSMSを送信します（推奨）" : 
                         "手動でSMS送信画面を表示します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("緊急連絡先") {
                    TextField("電話番号", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    Text("例: 090-1234-5678")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("緊急メッセージ") {
                    TextField("メッセージ", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Text("QRコードスキャンがタイムアウトした場合に送信されるメッセージです")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("プレビュー") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("送信先: \(phoneNumber.isEmpty ? "未設定" : phoneNumber)")
                            .font(.body)
                        
                        Text("メッセージ:")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Text(message.isEmpty ? "WakeOrPay緊急通知: アラームが1分以内に停止されませんでした。" : message)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("SMS設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                    }
                    .disabled(phoneNumber.isEmpty)
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("設定保存", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadSettings() {
        phoneNumber = SMSService.shared.getEmergencyContact() ?? ""
        message = SMSService.shared.getEmergencyMessage()
        useServerSMS = UserDefaults.standard.object(forKey: "USE_SERVER_SMS") as? Bool ?? true // デフォルトでサーバーSMSを使用
    }
    
    private func saveSettings() {
        SMSService.shared.setEmergencyContact(phoneNumber)
        SMSService.shared.setEmergencyMessage(message)
        UserDefaults.standard.set(useServerSMS, forKey: "USE_SERVER_SMS")
        
        alertMessage = "SMS設定を保存しました"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// MARK: - SMS Service

class SMSService: NSObject, ObservableObject {
    static let shared = SMSService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - SMS Settings
    
    func setEmergencyContact(_ phoneNumber: String) {
        UserDefaults.standard.set(phoneNumber, forKey: "EMERGENCY_SMS_CONTACT")
        print("緊急連絡先SMSを設定: \(phoneNumber)")
    }
    
    func getEmergencyContact() -> String? {
        return UserDefaults.standard.string(forKey: "EMERGENCY_SMS_CONTACT")
    }
    
    func setEmergencyMessage(_ message: String) {
        UserDefaults.standard.set(message, forKey: "EMERGENCY_SMS_MESSAGE")
        print("緊急SMSメッセージを設定: \(message)")
    }
    
    func getEmergencyMessage() -> String {
        return UserDefaults.standard.string(forKey: "EMERGENCY_SMS_MESSAGE") ?? "WakeOrPay緊急通知: アラームが1分以内に停止されませんでした。"
    }
    
    // MARK: - SMS Sending
    
    func canSendSMS() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    func sendEmergencySMS() {
        // サーバー自動送信を使用するかどうかをチェック（デフォルトでサーバーSMSを使用）
        let useServerSMS = UserDefaults.standard.object(forKey: "USE_SERVER_SMS") as? Bool ?? true
        
        if useServerSMS {
            print("サーバー自動送信を使用するため、クライアント側SMS送信をスキップ")
            return
        }
        
        guard canSendSMS() else {
            print("SMS送信ができません")
            return
        }
        
        guard let phoneNumber = getEmergencyContact(), !phoneNumber.isEmpty else {
            print("緊急連絡先が設定されていません")
            return
        }
        
        let message = getEmergencyMessage()
        print("緊急SMS送信: \(phoneNumber) - \(message)")
        
        // メインスレッドでSMS送信画面を表示
        DispatchQueue.main.async {
            self.presentSMSComposer(recipients: [phoneNumber], message: message)
        }
    }
    
    private func presentSMSComposer(recipients: [String], message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("SMS送信画面を表示できません")
            return
        }
        
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = recipients
        composer.body = message
        
        // 最上位のビューコントローラーを取得
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        topController.present(composer, animated: true)
    }
    
    // MARK: - Test Methods
    
    func sendTestSMS() {
        guard let phoneNumber = getEmergencyContact(), !phoneNumber.isEmpty else {
            print("テスト用SMS送信: 緊急連絡先が設定されていません")
            return
        }
        
        let testMessage = "WakeOrPayテスト通知: これはテストメッセージです。"
        print("テストSMS送信: \(phoneNumber) - \(testMessage)")
        
        DispatchQueue.main.async {
            self.presentSMSComposer(recipients: [phoneNumber], message: testMessage)
        }
    }
}

// MARK: - MFMessageComposeViewControllerDelegate

extension SMSService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        
        switch result {
        case .cancelled:
            print("SMS送信がキャンセルされました")
        case .sent:
            print("SMS送信が完了しました")
        case .failed:
            print("SMS送信に失敗しました")
        @unknown default:
            print("SMS送信結果が不明です")
        }
    }
}

#Preview {
    SettingsView()
}
