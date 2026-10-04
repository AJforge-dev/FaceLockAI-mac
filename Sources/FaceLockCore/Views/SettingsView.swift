import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var viewModel: AppViewModel

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section(header: Text("Face Recognition Sensitivity").font(.headline)) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Confidence Threshold:")
                        Spacer()
                        Text("\(Int(settings.confidenceThreshold * 100))%")
                            .bold()
                    }
                    Slider(value: $settings.confidenceThreshold, in: 0.60...0.95, step: 0.05)
                    Text("Higher values increase security but require strict alignment and lighting.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Auto-Lock Settings").font(.headline)) {
                Toggle("Lock Vault & Mac when face is absent", isOn: $settings.autoLockOnFaceAbsence)
                
                if settings.autoLockOnFaceAbsence {
                    Picker("Auto-Lock Delay", selection: $settings.autoLockDelaySeconds) {
                        Text("Instant (0s)").tag(0)
                        Text("3 Seconds").tag(3)
                        Text("5 Seconds").tag(5)
                        Text("10 Seconds").tag(10)
                        Text("15 Seconds").tag(15)
                    }
                }
            }

            Section(header: Text("Security & Storage").font(.headline)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Facial Geometry Data")
                            .font(.subheadline)
                            .bold()
                        Text("Biometric vectors are encrypted locally in macOS Keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Reset All Templates") {
                        viewModel.resetEnrollment()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding(24)
    }
}
