import SwiftUI

public struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HSplitView {
            // Left Column: Live Camera & Biometric Stream Monitor
            VStack(spacing: 16) {
                ZStack {
                    CameraPreviewRepresentable()
                        .aspectRatio(4/3, contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(statusBorderColor, lineWidth: 3)
                        )

                    // Animated Recognition Status Frame
                    VStack {
                        Spacer()
                        HStack {
                            Circle()
                                .fill(statusBorderColor)
                                .frame(width: 10, height: 10)
                            Text(viewModel.authStatus.rawValue)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(statusBorderColor)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(8)
                        .padding(12)
                    }
                }

                // Match Score Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Vision Recognition Match Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.confidence * 100))%")
                            .font(.caption)
                            .bold()
                    }
                    ProgressView(value: Double(viewModel.confidence))
                        .accentColor(statusBorderColor)
                }
                .padding(.horizontal, 4)

                // Secret Vault Quick Access Banner
                Button(action: { viewModel.selectedTab = .vault }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("FaceVault Secret Storage")
                                .font(.headline)
                            Text(viewModel.isVaultUnlocked ? "Unlocked — View Encrypted Media" : "Locked — Biometric Auth Required")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(viewModel.isVaultUnlocked ? Color.green.opacity(0.18) : Color.red.opacity(0.18))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.isVaultUnlocked ? Color.green : Color.red, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(16)
            .frame(minWidth: 340, maxWidth: .infinity)

            // Right Column: Professional Security Analytics & Activity Audit Logs
            VStack(alignment: .leading, spacing: 16) {
                Text("Security Analytics & System Health")
                    .font(.title2)
                    .bold()

                // Security Metrics Grid (3 Key Performance Indicators)
                HStack(spacing: 12) {
                    metricCard(
                        title: "Total Scans",
                        value: "\(viewModel.totalScansCount)",
                        icon: "eye.fill",
                        color: .blue
                    )
                    
                    metricCard(
                        title: "Verified Matches",
                        value: "\(viewModel.successfulMatchesCount)",
                        icon: "checkmark.shield.fill",
                        color: .green
                    )

                    metricCard(
                        title: "Security Alerts",
                        value: "\(viewModel.securityAlertsCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }

                Divider()

                // Real-Time Audit Log Timeline
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Security Audit Log")
                            .font(.headline)
                        Spacer()
                        Text("Real-Time Event Audit")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    List(viewModel.securityLogs) { log in
                        HStack(spacing: 12) {
                            Image(systemName: log.iconName)
                                .foregroundColor(colorForStatus(log.status))
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.event)
                                    .font(.system(size: 13, weight: .medium))
                                Text(formattedTime(log.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()

                            Text(log.status)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(colorForStatus(log.status).opacity(0.2))
                                .foregroundColor(colorForStatus(log.status))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                    .cornerRadius(10)
                }

                Spacer()

                // Bottom Status Bar
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("System Status: Operational | All Biometric Templates Encrypted in Keychain")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(minWidth: 380, maxWidth: .infinity)
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "Success", "Verified", "Secured", "Active": return .green
        case "Warning", "Alert": return .orange
        case "Locked": return .red
        default: return .blue
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private var statusBorderColor: Color {
        switch viewModel.authStatus {
        case .recognized: return .green
        case .unrecognized: return .red
        case .scanning: return .yellow
        case .noFaceDetected: return .gray
        case .locked: return .orange
        case .unauthenticated: return .blue
        }
    }
}
