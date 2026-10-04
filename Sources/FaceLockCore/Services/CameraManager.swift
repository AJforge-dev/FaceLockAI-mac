import Foundation
import AVFoundation
import AppKit
import Combine

public protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

public final class CameraManager: NSObject, ObservableObject, @unchecked Sendable, AVCaptureVideoDataOutputSampleBufferDelegate {
    public static let shared = CameraManager()
    
    public private(set) var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.facelock.ai.cameraQueue")
    
    public weak var delegate: CameraManagerDelegate?
    @Published public private(set) var isRunning = false
    @Published public private(set) var hasPermission = false
    
    private override init() {
        super.init()
    }
    
    public func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            Task { @MainActor in self.hasPermission = true }
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.hasPermission = granted
                    if granted {
                        self.setupSession()
                    }
                }
            }
        default:
            Task { @MainActor in self.hasPermission = false }
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high
            
            // Input Device
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                    }
                } catch {
                    print("Error configuring camera input: \(error)")
                }
            }
            
            // Output Data Stream
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                Task { @MainActor in self.isRunning = true }
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                Task { @MainActor in self.isRunning = false }
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}

// MARK: - NSView Camera Preview Layer Wrapper
public class CameraPreviewView: NSView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    public func setupSession(_ session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = self.bounds
        self.layer?.addSublayer(layer)
        self.previewLayer = layer
    }
    
    public override func layout() {
        super.layout()
        previewLayer?.frame = self.bounds
    }
}
