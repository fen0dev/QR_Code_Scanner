//
//  ScannerView.swift
//  QR_Code_Scanner
//
//  Created by Giuseppe, De Masi on 20/04/23.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    
    //properties
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    @State private var permission: Permission = .idle
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var openURL
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State private var scannedCode: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Color("Blue"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Place the QR Code inside this area")
                .font(.title3)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 20)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer(minLength: 0)
            
            ///scanner
            GeometryReader {
                let size = $0.size
                ZStack {
                    
                    CamerView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.95)
                    
                    ForEach(0...4, id: \.self) {index in
                        
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                        //trimming to get the QR edges
                            .trim(from: 0.61, to: 0.64)
                            .stroke(Color("Blue"), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                        
                    }
                }
                //to make it square
                .frame(width: size.width, height: size.width)
                //scanning animation
                .overlay(alignment: .top, content: {
                    Rectangle()
                        .fill(.pink)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x:0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width : 0)
                })
                //to center it. Make it as comment to see differences
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            
            Button {
                
                if !session.isRunning && permission == .approved {
                    re_activateCamera()
                    activate_Animation()
                }
                
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            
        }
        .padding(15)
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError) {
            
            //if permission denied, redirect user to phone settings
            if permission == .denied {
                
                Button("Settings"){
                    let settingString = UIApplication.openSettingsURLString
                    if let settingURL = URL(string: settingString) {
                        
                        //opening app's settings with openURL SwiftUI API
                        openURL(settingURL)
                    }
                }
                //along with cancel button
                Button("Cancel", role: .cancel) {
                    
                }
            }
        }
        .onChange(of: qrDelegate.scannedCode) { newValue in
            if let code = newValue {
                scannedCode = code
                //when the first code is scanned, stop camera scanning and use toggle button to start new scan.
                session.stopRunning()
                
                //deactivation of animation since device scanned 1st code.
                deActivate_Animation()
                
                // delete previous data scan on delegate
                qrDelegate.scannedCode = nil
            }
        }
        .onDisappear {
            session.stopRunning()
        }
    }
    
    //re-activate camera for new scan
    func re_activateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }

    //activate animation func
    func activate_Animation() {
        withAnimation(.easeInOut(duration: 0.85).delay(0.15).repeatForever(autoreverses: true)) {
                isScanning = true
        }
    }
    
    //de-activate animation func
    func deActivate_Animation() {
        withAnimation(.easeInOut(duration: 0.85)) {
                isScanning = false
        }
    }
    
    //checking camera and ask for permission
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                
            case .authorized:
                permission = .approved
                setUpCamera()
                
            case .notDetermined:
                
                if await AVCaptureDevice.requestAccess(for: .video) {
                    //permission granted
                    permission = .approved
                    
                    if session.inputs.isEmpty {
                        //New setup, as device must recognize when old session is over and new session begins and so its features
                        setUpCamera()
                    } else {
                        //existing one
                        re_activateCamera()
                    }
                    
                } else {
                    //permission denied
                    permission = .denied
                    //present error message
                    showErrorMessage("Please provide access to the camera to continue.")
                }
                
            case .denied, .restricted:
                permission = .denied
                showErrorMessage("Please provide access to the camera to continue.")
            default: break
            }
        }
    }
    //set up camera
    func setUpCamera() {
        do {
            
            //find camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back).devices.first else {
                showErrorMessage("UNKNOWN DEVICE ERROR")
                return
            }
            
            //camera input
            let input = try AVCaptureDeviceInput(device: device)
            //optional: for extra safety, checking input & output
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                showErrorMessage("UNKNOWN INPUT/OUTPUT ERROR")
                return
            }
            
            //adding input and output to camnera session
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            //setting output to read QR code
            qrOutput.metadataObjectTypes = [.qr]
            
            //adding delegate to retreive the fetched QR code from camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            //session must be started o background thread
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            activate_Animation()
            
        } catch {
            
            showErrorMessage(error.localizedDescription)
        }
    }
    
    //show error
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError.toggle()
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
