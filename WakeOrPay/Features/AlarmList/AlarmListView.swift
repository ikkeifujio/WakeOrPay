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
                    VStack {
                        // テストボタン
                        testButtonsView
                        
                        // アラーム再生中の停止ボタン
                        if AlarmService.shared.isPlaying {
                            alarmStopView
                        }
                        
                        alarmListView
                    }
                }
            }
            .navigationTitle("WakeOrPay")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("設定") {
                        showingSettings = true
                    }
                    .foregroundColor(.blue)
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
            .alert("QRコード", isPresented: $showingQRAlert) {
                Button("OK") { }
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
            
            // デバッグ情報を表示
            print("=== WakeOrPay デバッグ情報 ===")
            print("アラーム数: \(viewModel.alarms.count)")
            print("有効なアラーム数: \(viewModel.enabledAlarms.count)")
            print("次のアラーム: \(viewModel.nextAlarm?.title ?? "なし")")
            print("===============================")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
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
    
    // MARK: - Test Buttons View
    
    private var testButtonsView: some View {
        HStack(spacing: 8) {
            Button("音テスト") {
                SoundService.shared.playSimpleTestSound()
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange)
            .cornerRadius(12)
            
            Button("アラームテスト") {
                print("アラームテストボタンがタップされました")
                // QRコード付きのテストアラームを開始
                let testAlarm = Alarm(
                    title: "テストアラーム",
                    time: Date(),
                    isEnabled: true,
                    soundName: "default",
                    volume: 0.8,
                    qrCodeRequired: true
                )
                print("テストアラームを作成: \(testAlarm.title) (QRコード必要)")
                AlarmService.shared.startAlarm(testAlarm)
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.yellow)
            .cornerRadius(12)
            
            Button("QRスキャン") {
                showingQRScanner = true
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.cyan)
            .cornerRadius(12)
            
            Button("QR生成") {
                // テスト用のQRコードを生成してコンソールに表示
                let testAlarmId = UUID().uuidString
                let qrCodeString = "WakeOrPay:Stop:\(testAlarmId)"
                print("テスト用QRコード: \(qrCodeString)")
                
                // 簡単なアラートで表示
                showingQRAlert = true
                qrCodeMessage = qrCodeString
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.purple)
            .cornerRadius(12)
            
            Button("簡単テスト") {
                print("簡単テストボタンがタップされました")
                // 最もシンプルな音テスト
                SoundService.shared.playSimpleTestSound()
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
        guard !isScanning else { return previewLayer }
        
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("カメラにアクセスできません")
            return nil
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            
            self.captureSession = captureSession
            self.previewLayer = previewLayer
            self.isScanning = true
            
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
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
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        if validateQRCode(stringValue) {
            stopScanning()
            
            // アラームサービスにQRコード検証を通知
            DispatchQueue.main.async {
                let isValid = AlarmService.shared.validateQRCode(stringValue)
                if isValid {
                    print("QRコードが有効です: \(stringValue)")
                } else {
                    print("QRコードが無効です: \(stringValue)")
                }
            }
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let previewLayer = scannerService.startScanning() {
                QRCodePreviewView(previewLayer: previewLayer)
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

struct QRCodePreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

#Preview {
    AlarmListView()
}