import SwiftUI

public struct EnrollmentView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("Face Enrollment")
                .font(.largeTitle)
                .bold()

            Text("Position your face directly in front of the camera under clear lighting.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Camera View & Guide
            ZStack {
                CameraPreviewRepresentable()
                    .frame(width: 380, height: 280)
                    .cornerRadius(16)
                    .shadow(radius: 8)

                // Face guide oval overlay
                Ellipse()
                    .stroke(viewModel.isEnrolling ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .frame(width: 200, height: 240)

                if viewModel.isEnrolling {
                    VStack {
                        Spacer()
                        ProgressView("Capturing sample \(viewModel.capturedSamplesCount)/\(viewModel.requiredSamplesCount)...", value: viewModel.enrollmentProgress)
                            .progressViewStyle(.linear)
                            .padding(16)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding()
                    }
                }
            }

            Text(viewModel.statusMessage)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(viewModel.isEnrolled ? .green : .primary)

            // Action Buttons
            HStack(spacing: 16) {
                if viewModel.isEnrolled {
                    Button(action: { viewModel.resetEnrollment() }) {
                        Label("Reset Facial Templates", systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Button(action: { viewModel.startEnrollment() }) {
                        Label("Re-enroll Face", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { viewModel.startEnrollment() }) {
                        Label(viewModel.isEnrolling ? "Enrolling..." : "Start Enrollment", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isEnrolling)
                }
            }

            Spacer()
        }
        .padding(30)
    }
}
