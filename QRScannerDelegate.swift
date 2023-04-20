//
//  QRScannerDelegate.swift
//  QR_Code_Scanner
//
//  Created by Giuseppe, De Masi on 20/04/23.
//

import SwiftUI
import AVKit

class QRScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    
    @Published var scannedCode: String?
    
    internal func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metaObject = metadataObjects.first {
            
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let Code = readableObject.stringValue else { return }
            
            print(Code)
            
            scannedCode = Code
        }
    }
}
