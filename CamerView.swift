//
//  CamerView.swift
//  QR_Code_Scanner
//
//  Created by Giuseppe, De Masi on 20/04/23.
//

import SwiftUI
import AVKit

struct CamerView: UIViewRepresentable {
    
    var frameSize: CGSize
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIViewType(frame: CGRect(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

