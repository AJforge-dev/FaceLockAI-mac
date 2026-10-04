import SwiftUI
import AppKit

public struct VaultView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isTargetedForDrop: Bool = false
    @State private var showAddNoteSheet: Bool = false
    @State private var noteTitle: String = ""
    @State private var noteBody: String = ""
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.isVaultUnlocked {
                // UNLOCKED ENCRYPTED VAULT VIEW
                VStack(spacing: 16) {
                    // Top Bar: Search, Category Filters & Actions
                    HStack(spacing: 12) {
                        // Native Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search files...", text: $viewModel.searchQuery)
                                .textFieldStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .frame(maxWidth: 240)

                        // Category Filter Segment
                        Picker("Category", selection: $viewModel.selectedVaultCategory) {
                            ForEach(VaultCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        // Import File Button
                        Button(action: { viewModel.importFilesToVault() }) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)

                        // New Secret Note Button
                        Button(action: { showAddNoteSheet = true }) {
                            Label("Note", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)

                        // Lock Vault Button
                        Button(action: { viewModel.lockVault(triggerSystemLock: false) }) {
                            Image(systemName: "lock.fill")
                        }
                        .buttonStyle(.bordered)
                        .help("Lock Vault")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Divider()

                    // Filtered Items Grid / List
                    let items = filteredVaultItems

                    if items.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            Image(systemName: "lock.doc")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No files in vault")
                                .font(.headline)
                            Text("Drag and drop files here or click Import to encrypt files at rest using AES-256 GCM.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 380)
                            
                            Button(action: { viewModel.importFilesToVault() }) {
                                Label("Import Files", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)], spacing: 16) {
                                ForEach(items) { item in
                                    fileCardView(item: item)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                    handleFileDrop(providers: providers)
                }
                .sheet(isPresented: $showAddNoteSheet) {
                    VStack(spacing: 16) {
                        Text("Create Encrypted Note")
                            .font(.headline)
                        TextField("Title", text: $noteTitle)
                            .textFieldStyle(.roundedBorder)
                        TextEditor(text: $noteBody)
                            .frame(height: 120)
                            .border(Color.gray.opacity(0.2))
                        
                        HStack {
                            Button("Cancel") { showAddNoteSheet = false }
                            Button("Save & Encrypt") {
                                if !noteTitle.isEmpty {
                                    viewModel.addSecretNote(title: noteTitle, note: noteBody)
                                    noteTitle = ""
                                    noteBody = ""
                                    showAddNoteSheet = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(20)
                    .frame(width: 340, height: 280)
                }
            } else {
                // LOCKED VAULT SCREEN
                VStack(spacing: 20) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.red)
                    }

                    Text("Vault Locked")
                        .font(.title2)
                        .bold()

                    Text("Files are encrypted at rest using AES-GCM.\nAuthenticate via Face ID, Touch ID, PIN, or Password to unlock.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)

                    // Auth Actions Group
                    VStack(spacing: 12) {
                        if TouchIDService.shared.isTouchIDAvailable() {
                            Button(action: { viewModel.authenticateWithTouchID() }) {
                                Label("Unlock with Touch ID", systemImage: "touchid")
                                    .frame(width: 220)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }

                        Button(action: { viewModel.selectedTab = .faceAccess }) {
                            Label("Unlock with Face ID", systemImage: "faceid")
                                .frame(width: 220)
                        }
                        .buttonStyle(.bordered)

                        HStack(spacing: 12) {
                            SecureField("PIN", text: $viewModel.pinInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                            Button("Unlock PIN") {
                                viewModel.authenticateWithPIN()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 10)

                    if let error = viewModel.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(30)
            }
        }
    }

    private var filteredVaultItems: [VaultItem] {
        viewModel.vaultItems.filter { item in
            let matchesCategory = (viewModel.selectedVaultCategory == .all || item.category == viewModel.selectedVaultCategory)
            let matchesQuery = viewModel.searchQuery.isEmpty || item.name.localizedCaseInsensitiveContains(viewModel.searchQuery)
            return matchesCategory && matchesQuery
        }
    }

    private func fileCardView(item: VaultItem) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 90)

                Image(systemName: item.category.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }

            Text(cleanFileName(item.name))
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .onTapGesture {
            viewModel.decryptAndOpenFile(item: item)
        }
    }

    private func cleanFileName(_ name: String) -> String {
        if name.hasSuffix(".enc") {
            return String(name.dropLast(4))
        }
        return name
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in
                        let destDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FaceVault_EncryptedData/Documents")
                        let destURL = destDir.appendingPathComponent(url.lastPathComponent + ".enc")
                        try? VaultEncryptionService.shared.encryptFile(at: url, destinationURL: destURL)
                        viewModel.refreshVaultItems()
                        viewModel.recordActivity(title: "Dropped & Encrypted File", category: "Vault", icon: "square.and.arrow.down")
                    }
                }
            }
        }
        return true
    }
}
