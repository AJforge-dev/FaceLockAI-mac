import SwiftUI
import AVFoundation
import AppKit

public struct CameraPreviewRepresentable: NSViewRepresentable {
    @ObservedObject var cameraManager = CameraManager.shared

    public init() {}

    public func makeNSView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView(frame: .zero)
        view.setupSession(cameraManager.captureSession)
        return view
    }

    public func updateNSView(_ nsView: CameraPreviewView, context: Context) {}
}
