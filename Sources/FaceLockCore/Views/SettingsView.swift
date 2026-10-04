import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var viewModel: AppViewModel
    
    @State private var newPIN: String = ""
    @State private var newPass: String = ""
    @State private var showPINSheet: Bool = false
    @State private var showPassSheet: Bool = false

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Security Settings")
                .font(.title2)
                .bold()
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Text("Configure inactivity locking, backup recovery credentials, and biometric templates.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            Divider()

            Form {
                Section(header: Text("Inactivity & Auto-Lock").font(.headline)) {
                    Toggle("Auto-lock when face is absent", isOn: $settings.autoLockOnFaceAbsence)
                    
                    if settings.autoLockOnFaceAbsence {
                        Picker("Inactivity Timeout", selection: $settings.autoLockDelaySeconds) {
                            Text("Instant (0s)").tag(0)
                            Text("3 Seconds").tag(3)
                            Text("5 Seconds").tag(5)
                            Text("10 Seconds").tag(10)
                            Text("15 Seconds").tag(15)
                        }
                    }

                    Button("Lock Vault Now") {
                        viewModel.lockVault(triggerSystemLock: false)
                    }
                    .buttonStyle(.bordered)
                }

                Section(header: Text("Recovery Methods & Authentication").font(.headline)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Security PIN")
                                .font(.subheadline)
                                .bold()
                            Text(SecureStorageService.shared.hasPIN() ? "PIN configured in Keychain." : "No PIN set.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(SecureStorageService.shared.hasPIN() ? "Change PIN" : "Set Up PIN") {
                            showPINSheet = true
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Master Password")
                                .font(.subheadline)
                                .bold()
                            Text(SecureStorageService.shared.hasPassword() ? "Master Password configured in Keychain." : "No Master Password set.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(SecureStorageService.shared.hasPassword() ? "Change Password" : "Set Up Password") {
                            showPassSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section(header: Text("Biometric Templates & Vision Sensitivity").font(.headline)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Confidence Threshold:")
                            Spacer()
                            Text("\(Int(settings.confidenceThreshold * 100))%")
                                .bold()
                        }
                        Slider(value: $settings.confidenceThreshold, in: 0.60...0.95, step: 0.05)
                    }

                    HStack {
                        Text("Facial Geometry Data")
                        Spacer()
                        Button("Delete Template") {
                            viewModel.resetEnrollment()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }

                Section(header: Text("Privacy Controls & Disclaimers").font(.headline)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            Text("Local Keychain Encryption")
                                .font(.subheadline)
                                .bold()
                        }
                        Text("All biometric vectors, PINs, and AES-256 keys are stored locally on your Mac. No cloud services or tracking APIs are utilized.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider().padding(.vertical, 4)

                        Text("Note: Webcam facial matching protects local vault data and auto-locks workstation display. It does not replace Apple's Secure Enclave macOS system login screen.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showPINSheet) {
            VStack(spacing: 16) {
                Text("Set Security PIN")
                    .font(.headline)
                SecureField("Create PIN", text: $newPIN)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                HStack {
                    Button("Cancel") { showPINSheet = false }
                    Button("Save PIN") {
                        if !newPIN.isEmpty {
                            viewModel.setupPIN(newPIN)
                            newPIN = ""
                            showPINSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 300, height: 180)
        }
        .sheet(isPresented: $showPassSheet) {
            VStack(spacing: 16) {
                Text("Set Master Password")
                    .font(.headline)
                SecureField("Create Password", text: $newPass)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                
                HStack {
                    Button("Cancel") { showPassSheet = false }
                    Button("Save Password") {
                        if !newPass.isEmpty {
                            viewModel.setupPassword(newPass)
                            newPass = ""
                            showPassSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 320, height: 180)
        }
    }
}
