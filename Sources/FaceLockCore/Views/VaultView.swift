import SwiftUI
import AppKit

public struct VaultView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var newPIN: String = ""
    @State private var showPINSetup: Bool = false
    @State private var showAddNoteSheet: Bool = false
    @State private var noteTitle: String = ""
    @State private var noteBody: String = ""
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            if viewModel.isVaultUnlocked {
                // UNLOCKED SECRET VAULT (PHOTOS, MEDIA & DOCUMENTS)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Secret Protected Vault")
                                .font(.title)
                                .bold()
                            Text("Local Encrypted Directory: ~/Documents/FaceLockAI_SecretVault/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // ADD FILES / MEDIA BUTTON
                        Button(action: { viewModel.importFilesToVault() }) {
                            Label("Add Files / Media", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        // NEW SECRET NOTE BUTTON
                        Button(action: { showAddNoteSheet = true }) {
                            Label("New Secret Note", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.bordered)

                        // LOCK VAULT BUTTON
                        Button(action: { viewModel.lockVault(triggerSystemLock: false) }) {
                            Label("Lock Vault", systemImage: "lock.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }

                    // Categorization Filter Bar
                    HStack(spacing: 12) {
                        ForEach(VaultCategory.allCases) { cat in
                            Button(action: { viewModel.selectedVaultCategory = cat }) {
                                Label(cat.rawValue, systemImage: cat.iconName)
                            }
                            .tint(viewModel.selectedVaultCategory == cat ? .accentColor : .gray)
                            .buttonStyle(.bordered)
                        }
                    }

                    // Vault Content List
                    let filteredItems = viewModel.vaultItems.filter {
                        viewModel.selectedVaultCategory == .all || $0.category == viewModel.selectedVaultCategory
                    }

                    if filteredItems.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: viewModel.selectedVaultCategory.iconName)
                                .font(.system(size: 56))
                                .foregroundColor(.secondary)
                            Text("No items in \(viewModel.selectedVaultCategory.rawValue)")
                                .font(.headline)
                            Text("Click the 'Add Files / Media' button above to import your secret photos, videos, or documents into your encrypted vault.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 420)
                            
                            Button(action: { viewModel.importFilesToVault() }) {
                                Label("Add Files & Media Now", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        List(filteredItems) { item in
                            HStack(spacing: 16) {
                                Image(systemName: item.category.iconName)
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text(item.category.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                if let url = item.fileURL {
                                    Button("Open File") {
                                        NSWorkspace.shared.open(url)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(24)
                .sheet(isPresented: $showAddNoteSheet) {
                    VStack(spacing: 16) {
                        Text("Add Secret Note")
                            .font(.headline)
                        TextField("Title", text: $noteTitle)
                            .textFieldStyle(.roundedBorder)
                        TextEditor(text: $noteBody)
                            .frame(height: 100)
                            .border(Color.gray.opacity(0.3))
                        
                        HStack {
                            Button("Cancel") { showAddNoteSheet = false }
                            Button("Save to Vault") {
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
                    .frame(width: 340, height: 260)
                }
            } else {
                // LOCKED VAULT AUTHENTICATION SCREEN
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.red)

                    Text("Secret Vault Locked")
                        .font(.title)
                        .bold()

                    Text("Photos, Media, Documents & Secrets are protected.\nPresent your enrolled face to the camera or enter backup PIN.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)

                    // PIN Fallback Entry
                    if SecureStorageService.shared.hasPIN() {
                        VStack(spacing: 12) {
                            SecureField("Enter Backup PIN", text: $viewModel.pinInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 220)
                            
                            if let error = viewModel.pinError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button("Unlock with PIN") {
                                viewModel.authenticateWithPIN()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 10)
                    } else {
                        Button("Set Up Backup PIN") {
                            showPINSetup = true
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 10)
                    }

                    Spacer()
                }
                .padding(30)
                .sheet(isPresented: $showPINSetup) {
                    VStack(spacing: 16) {
                        Text("Set Security PIN")
                            .font(.headline)
                        SecureField("Create PIN", text: $newPIN)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        
                        HStack {
                            Button("Cancel") { showPINSetup = false }
                            Button("Save PIN") {
                                if !newPIN.isEmpty {
                                    viewModel.setupPIN(newPIN)
                                    showPINSetup = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(24)
                    .frame(width: 300, height: 180)
                }
            }
        }
    }
}
