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
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "faceid")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("FaceLock AI")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("macOS Biometric Vault")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)

                Divider()

                // Navigation Items List
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
                    Text(viewModel.isVaultUnlocked ? "Vault Unlocked" : "Vault Protected")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230)
        } detail: {
            switch viewModel.selectedTab {
            case .dashboard:
                DashboardView(viewModel: viewModel)
            case .enrollment:
                EnrollmentView(viewModel: viewModel)
            case .vault:
                VaultView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .frame(minWidth: 920, minHeight: 620)
    }

    private func iconForTab(_ tab: AppTab) -> String {
        switch tab {
        case .dashboard: return "shield.checkered"
        case .enrollment: return "person.badge.shield.checkmark"
        case .vault: return "lock.rectangle.stack"
        case .settings: return "gearshape.fill"
        }
    }
}
