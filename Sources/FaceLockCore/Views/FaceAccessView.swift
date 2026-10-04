import SwiftUI

public struct FaceAccessView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Face Access & Verification")
                        .font(.title2)
                        .bold()
                    Text("Webcam face recognition runs only during active verification or enrollment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Divider()

            HSplitView {
                // Left Column: Camera Preview (Active only during session)
                VStack(spacing: 16) {
                    ZStack {
                        if viewModel.isCameraActive {
                            CameraPreviewRepresentable()
                                .aspectRatio(4/3, contentMode: .fit)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(statusColor, lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .aspectRatio(4/3, contentMode: .fit)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.fill.badge.ellipsis")
                                            .font(.system(size: 36))
                                            .foregroundColor(.secondary)
                                        Text("Camera Offline")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Camera activates only during active verification or enrollment.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                )
                        }
                    }

                    if viewModel.isCameraActive {
                        HStack {
                            Circle().fill(statusColor).frame(width: 8, height: 8)
                            Text(viewModel.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // On-Demand Verification Buttons
                    HStack(spacing: 12) {
                        if !viewModel.isCameraActive {
                            Button(action: { viewModel.startCamera() }) {
                                Label("Start Verification", systemImage: "eye.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: { viewModel.stopCamera() }) {
                                Label("Stop Camera", systemImage: "camera.metering.unknown")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(20)
                .frame(minWidth: 320, maxWidth: .infinity)

                // Right Column: Enrollment & Recovery Status
                VStack(alignment: .leading, spacing: 20) {
                    Text("Biometric Status & Templates")
                        .font(.headline)

                    // Enrollment Status Card
                    HStack(spacing: 14) {
                        Image(systemName: viewModel.isEnrolled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title)
                            .foregroundColor(viewModel.isEnrolled ? .green : .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isEnrolled ? "Face Template Enrolled" : "No Face Enrolled")
                                .font(.subheadline)
                                .bold()
                            Text(viewModel.isEnrolled ? "Facial geometry vectors stored safely in macOS Keychain." : "Enroll face samples to enable camera verification.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)

                    if viewModel.isEnrolling {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: viewModel.enrollmentProgress)
                            Text("Capturing sample \(viewModel.capturedSamplesCount)/\(viewModel.requiredSamplesCount)...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Enrollment Controls
                    HStack(spacing: 12) {
                        Button(action: { viewModel.startEnrollment() }) {
                            Label(viewModel.isEnrolled ? "Re-enroll Face" : "Enroll Face", systemImage: "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isEnrolling)

                        if viewModel.isEnrolled {
                            Button(action: { viewModel.resetEnrollment() }) {
                                Label("Delete Template", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }

                    Divider()

                    // Recovery Configuration Notice
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recovery & Backup Methods")
                            .font(.subheadline)
                            .bold()
                        Text("Configured PIN & Master Passwords allow vault access if camera or lighting conditions fail.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(20)
                .frame(minWidth: 300, maxWidth: .infinity)
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.authStatus {
        case .recognized: return .green
        case .unrecognized: return .red
        case .scanning: return .yellow
        default: return .gray
        }
    }
}
