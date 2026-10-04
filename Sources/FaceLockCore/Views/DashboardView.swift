import SwiftUI

public struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var activeGameTab: Int = 0 // 0: Ludo, 1: Car Parking
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HSplitView {
            // Left Column: Live Camera & Recognition State
            VStack(spacing: 16) {
                ZStack {
                    CameraPreviewRepresentable()
                        .aspectRatio(4/3, contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(statusBorderColor, lineWidth: 3)
                        )

                    // Animated Recognition Frame Overlay
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

                // Confidence gauge
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Recognition Match Score")
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

                // Secret Vault Quick Access Banner Button
                Button(action: { viewModel.selectedTab = .vault }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Secret Vault (Photos, Media & Docs)")
                                .font(.headline)
                            Text(viewModel.isVaultUnlocked ? "Unlocked - Click to View Media" : "Locked - Face Auth Required")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(viewModel.isVaultUnlocked ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
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
            .frame(minWidth: 320, maxWidth: .infinity)

            // Right Column: Interactive Mac Games (Ludo & Car Parking)
            VStack(alignment: .leading, spacing: 14) {
                Picker("Select Game", selection: $activeGameTab) {
                    Text("🎲 Ludo Board").tag(0)
                    Text("🚗 Car Parking Sim").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                if activeGameTab == 0 {
                    LudoGameView()
                } else {
                    CarParkingGameView()
                }

                Spacer()

                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                    Text("FaceLock Security Active — Continuous Face Monitoring running in background.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(minWidth: 360, maxWidth: .infinity)
        }
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
