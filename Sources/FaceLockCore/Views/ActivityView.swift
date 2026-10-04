import SwiftUI

public struct ActivityView: View {
    @ObservedObject var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Activity")
                        .font(.title2)
                        .bold()
                    Text("Genuine audit log of authentication attempts, vault locking, and file imports.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button("Clear History") {
                    viewModel.activityEvents.removeAll()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Divider()

            if viewModel.activityEvents.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No Activity Logged")
                        .font(.headline)
                    Text("Events will appear here as you unlock your vault, import files, or update settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.activityEvents) { event in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(colorForCategory(event.category).opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: event.iconName)
                                .foregroundColor(colorForCategory(event.category))
                                .font(.system(size: 14, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.system(size: 13, weight: .medium))
                            Text(event.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(formattedDate(event.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
    }

    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "Authentication": return .green
        case "Security Alert": return .red
        case "Vault": return .blue
        case "Face Access": return .purple
        default: return .primary
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
