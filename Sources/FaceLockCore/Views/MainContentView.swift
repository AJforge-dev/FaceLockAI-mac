import SwiftUI

public struct MainContentView: View {
    @StateObject private var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header Brand Section
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("FaceVault")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Encrypted File Storage")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()

                // Sidebar Navigation Items
                List(AppTab.allCases, selection: $viewModel.selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: iconForTab(tab))
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .listStyle(.sidebar)

                Spacer()

                Divider()

                // Security Status Badge Footer
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isVaultUnlocked ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isVaultUnlocked ? "Vault Unlocked" : "Vault Locked")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    if viewModel.isCameraActive {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch viewModel.selectedTab {
            case .vault:
                VaultView(viewModel: viewModel)
            case .faceAccess:
                FaceAccessView(viewModel: viewModel)
            case .activity:
                ActivityView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 880, minHeight: 600)
    }

    private func iconForTab(_ tab: AppTab) -> String {
        switch tab {
        case .vault: return "folder.fill"
        case .faceAccess: return "faceid"
        case .activity: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
