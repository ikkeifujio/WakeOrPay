//
//  QRCodeUtils.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import CoreImage
import UIKit

struct QRCodeUtils {
    
    // MARK: - QR Code Generation
    
    static func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // 高解像度に変換
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    static func generateAlarmStopQRCode() -> UIImage? {
        return generateQRCode(from: AppConstants.QRCode.defaultData)
    }
    
    // MARK: - QR Code Validation
    
    static func isValidAlarmStopQRCode(_ data: String) -> Bool {
        return data.hasPrefix(AppConstants.QRCode.dataPrefix) && 
               data.contains("AlarmStop")
    }
    
    static func extractQRCodeData(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
        
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
              let qrCodeFeature = features.first,
              let messageString = qrCodeFeature.messageString else {
            return nil
        }
        
        return messageString
    }
    
    // MARK: - QR Code Display
    
    static func createQRCodeView(data: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard let qrImage = generateQRCode(from: data) else { return nil }
        
        // サイズを調整
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            qrImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Default QR Code Data
    
    static func getDefaultQRCodeData() -> String {
        return AppConstants.QRCode.defaultData
    }
    
    static func createCustomQRCodeData(for alarmId: UUID) -> String {
        return "\(AppConstants.QRCode.dataPrefix)AlarmStop:\(alarmId.uuidString)"
    }
    
    // MARK: - QR Code Scanning
    
    static func canScanQRCode() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    // MARK: - Error Handling
    
    enum QRCodeError: LocalizedError {
        case invalidData
        case generationFailed
        case scanningNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "無効なQRコードデータです"
            case .generationFailed:
                return "QRコードの生成に失敗しました"
            case .scanningNotAvailable:
                return "QRコードスキャンが利用できません"
            }
        }
    }
}
