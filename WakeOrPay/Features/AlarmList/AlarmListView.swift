//
//  AlarmListView.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import SwiftUI
import UIKit
import Foundation
import AVFoundation

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmListViewModel()
    @State private var showingSettings = false
    @State private var showingQRScanner = false
    @State private var showingQRAlert = false
    @State private var qrCodeMessage = ""
    @State private var qrCodeData = ""
    @State private var showingHistory = false // Added for history view
    @State private var isCountdownActive = false
    @State private var remainingTime = 60
    @State private var countdownTimer: Timer?
    @State private var alarmFireDate: Date?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .font(.body)
                } else if viewModel.alarms.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 8) {
                        // テストボタン
                        qrCodeButtonsView
                        
                        // アラーム再生中の停止ボタン
                        if AlarmService.shared.isPlaying {
                            alarmStopView
                        }
                        
                        alarmListView
                    }
                }
            }
            .navigationTitle("WakeOrPay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("設定") {
                            showingSettings = true
                        }
                        .foregroundColor(.blue)
                        
                                // Button("履歴") {
                                //     showingHistory = true
                                // }
                                // .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddAlarm) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
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
                    .sheet(isPresented: $showingQRScanner) {
                        QRScannerView()
                    }
                    // .sheet(isPresented: $showingHistory) {
                    //     HistoryView()
                    // }
            .alert("QRコード", isPresented: $showingQRAlert) {
                Button("OK") { }
                Button("コピー") {
                    UIPasteboard.general.string = qrCodeData
                }
            } message: {
                Text(qrCodeMessage)
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
            loadCountdownState()
            
            // デバッグ情報を表示
            print("=== WakeOrPay デバッグ情報 ===")
            print("アラーム数: \(viewModel.alarms.count)")
            print("有効なアラーム数: \(viewModel.enabledAlarms.count)")
            print("次のアラーム: \(viewModel.nextAlarm?.title ?? "なし")")
            print("===============================")
        }
        .onDisappear {
            // カウントダウン状態を保存
            if isCountdownActive {
                saveCountdownState()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // テストボタン
            qrCodeButtonsView
            
            Image(systemName: "alarm")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("アラームがありません")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("右上の + ボタンから\nアラームを追加してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("アラームを追加") {
                viewModel.showAddAlarm()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
    
    // MARK: - Alarm List
    
    private var alarmListView: some View {
        VStack(spacing: 0) {
            // 次のアラーム表示
            if let nextAlarm = viewModel.nextAlarm {
                nextAlarmCard(nextAlarm)
            }
            
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
                        .tint(.orange)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                
                Text("次のアラーム")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.title)
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text(alarm.timeString)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { viewModel.toggleAlarm(alarm) }) {
                    Image(systemName: alarm.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(alarm.isEnabled ? .yellow : .green)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - QR Code Buttons View
    
    private var qrCodeButtonsView: some View {
        HStack(spacing: 8) {
            Button("QRスキャン") {
                print("QRスキャンボタンがタップされました")
                
                // カメラ権限を事前チェック
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                    print("カメラ権限が許可されています - スキャン画面を表示")
                    showingQRScanner = true
                case .notDetermined:
                    print("カメラ権限が未決定です - リクエストしてからスキャン画面を表示")
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            if granted {
                                print("カメラ権限が許可されました - スキャン画面を表示")
                                showingQRScanner = true
                            } else {
                                print("カメラ権限が拒否されました")
                                showingQRAlert = true
                                qrCodeMessage = "カメラのアクセス許可が必要です。設定で許可してください。"
                            }
                        }
                    }
                case .denied, .restricted:
                    print("カメラ権限が拒否または制限されています")
                    showingQRAlert = true
                    qrCodeMessage = "カメラのアクセス許可が必要です。設定で許可してください。"
                @unknown default:
                    print("未知のカメラ権限状態")
                    showingQRAlert = true
                    qrCodeMessage = "カメラのアクセス許可が必要です。設定で許可してください。"
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.cyan)
            .cornerRadius(12)
            
            Button("QR生成") {
                // テスト用のQRコードを生成して表示
                let testAlarmId = UUID().uuidString
                let qrCodeString = "WakeOrPay:Stop:\(testAlarmId)"
                print("テスト用QRコード: \(qrCodeString)")
                
                // データを保存
                qrCodeData = qrCodeString
                
                // クリップボードにコピー
                UIPasteboard.general.string = qrCodeString
                
                // アラートで表示
                showingQRAlert = true
                qrCodeMessage = "QRコードデータをクリップボードにコピーしました:\n\n\(qrCodeString)\n\nこのデータをQRコード生成アプリで使用してください"
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.purple)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    // MARK: - Alarm Stop View
    
    private var alarmStopView: some View {
        VStack(spacing: 16) {
            Text("アラームが鳴っています")
                .font(.headline)
                .foregroundColor(.red)
            
            if let currentAlarm = AlarmService.shared.currentAlarm {
                Text(currentAlarm.title)
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Button("アラームを停止") {
                AlarmService.shared.stopCurrentAlarm()
            }
            .buttonStyle(StopButtonStyle())
        }
        .padding(24)
        .background(.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
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
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(alarm.timeString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: alarm.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(alarm.isEnabled ? .green : .red)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

struct StopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.red)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

// MARK: - QR Code Scanner Service

class QRCodeScannerService: NSObject, ObservableObject {
    static let shared = QRCodeScannerService()
    
    @Published var isScanning: Bool = false
    @Published var scannedCode: String = ""
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private override init() {
        super.init()
    }
    
    // MARK: - QR Code Scanning
    
    func startScanning() -> AVCaptureVideoPreviewLayer? {
        print("QRスキャン開始を試行中...")
        guard !isScanning else { 
            print("既にスキャン中です")
            return previewLayer 
        }
        
        // カメラ権限をチェック
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("カメラ権限が許可されています")
            return setupCamera()
        case .notDetermined:
            print("カメラ権限が未決定です。リクエストします...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        print("カメラ権限が許可されました")
                        _ = self?.setupCamera()
                    } else {
                        print("カメラ権限が拒否されました")
                    }
                }
            }
            return nil
        case .denied, .restricted:
            print("カメラ権限が拒否または制限されています")
            return nil
        @unknown default:
            print("未知のカメラ権限状態")
            return nil
        }
    }
    
    private func setupCamera() -> AVCaptureVideoPreviewLayer? {
        print("カメラセットアップ開始")
        let captureSession = AVCaptureSession()
        
        // セッション設定を最適化
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("カメラにアクセスできません - デバイスが見つかりません")
            return nil
        }
        
        print("カメラデバイスが見つかりました: \(videoCaptureDevice.localizedName)")
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("ビデオ入力が追加されました")
            } else {
                print("ビデオ入力の追加に失敗しました")
                return nil
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                print("メタデータ出力が追加されました")
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                print("QRコード検出が設定されました")
            } else {
                print("メタデータ出力の追加に失敗しました")
                return nil
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            print("プレビューレイヤーが作成されました")
            
            self.captureSession = captureSession
            self.previewLayer = previewLayer
            self.isScanning = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                print("カメラセッションが開始されました")
                
                // セッションの状態を確認
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("セッション状態: \(captureSession.isRunning ? "実行中" : "停止中")")
                }
            }
            
            print("QRコードスキャンを開始しました")
            return previewLayer
            
        } catch {
            print("カメラセットアップエラー: \(error)")
            return nil
        }
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isScanning = false
        
        print("QRコードスキャンを停止しました")
    }
    
    // MARK: - QR Code Validation
    
    func validateQRCode(_ code: String) -> Bool {
        guard code.hasPrefix("WakeOrPay:Stop:") else { return false }
        
        let alarmIdString = String(code.dropFirst("WakeOrPay:Stop:".count))
        guard UUID(uuidString: alarmIdString) != nil else { return false }
        
        scannedCode = code
        return true
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print("QRコード検出を試行中... 検出数: \(metadataObjects.count)")
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            print("QRコードデータの読み取りに失敗")
            return
        }
        
        print("QRコードを検出しました: \(stringValue)")
        
        if validateQRCode(stringValue) {
            print("QRコードが有効です - スキャンを停止します")
            stopScanning()
            
            // アラームサービスにQRコード検証を通知
            DispatchQueue.main.async {
                let isValid = AlarmService.shared.validateQRCode(stringValue)
                if isValid {
                    print("アラームサービスでQRコードが有効と確認されました: \(stringValue)")
                } else {
                    print("アラームサービスでQRコードが無効と判定されました: \(stringValue)")
                }
            }
        } else {
            print("QRコードが無効です: \(stringValue)")
        }
    }
}

// MARK: - QR Scanner View

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scannerService = QRCodeScannerService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
            Color.black.ignoresSafeArea()
            
        if let previewLayer = scannerService.startScanning() {
            QRCodePreviewView(previewLayer: previewLayer)
                .onAppear {
                    print("QRCodePreviewViewが表示されました")
                }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("カメラにアクセスできません")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("設定でカメラのアクセス許可を確認してください")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("権限を確認") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
        }
            
            VStack {
                Spacer()
                
                HStack {
                    Button("キャンセル") {
                        scannerService.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack {
                        Text("QRコードをスキャン")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("アラーム停止用のQRコードを\nカメラにかざしてください")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button("手動入力") {
                        // 手動入力機能（将来実装）
                        alertMessage = "手動入力機能は実装予定です"
                        showingAlert = true
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
            .alert("情報", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onDisappear {
                scannerService.stopScanning()
            }
            }
        }
    }

struct QRCodePreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            self.previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Countdown Timer Management

extension AlarmListView {
    private func startCountdownTimer() {
        guard !isCountdownActive else { return }
        
        print("カウントダウンタイマーを開始")
        isCountdownActive = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopCountdownTimer()
            }
        }
    }
    
    private func stopCountdownTimer() {
        print("カウントダウンタイマーを停止")
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountdownActive = false
        remainingTime = 60
    }
    
    private func saveCountdownState() {
        UserDefaults.standard.set(isCountdownActive, forKey: "isCountdownActive")
        UserDefaults.standard.set(remainingTime, forKey: "remainingTime")
        if let fireDate = alarmFireDate {
            UserDefaults.standard.set(fireDate.timeIntervalSince1970, forKey: "alarmFireDate")
        }
    }
    
    private func loadCountdownState() {
        isCountdownActive = UserDefaults.standard.bool(forKey: "isCountdownActive")
        remainingTime = UserDefaults.standard.integer(forKey: "remainingTime")
        if remainingTime <= 0 {
            remainingTime = 60
        }
        
        let fireDateTimestamp = UserDefaults.standard.double(forKey: "alarmFireDate")
        if fireDateTimestamp > 0 {
            alarmFireDate = Date(timeIntervalSince1970: fireDateTimestamp)
        }
    }
}


#Preview {
    AlarmListView()
}