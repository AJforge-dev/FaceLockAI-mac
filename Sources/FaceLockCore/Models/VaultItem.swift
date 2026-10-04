import Foundation

public enum VaultCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All Files"
    case photos = "Photos & Media"
    case documents = "Documents"
    case secrets = "Secret Notes"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all: return "folder.fill"
        case .photos: return "photo.stack.fill"
        case .documents: return "doc.richtext.fill"
        case .secrets: return "key.fill"
        }
    }
}

public struct VaultItem: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var name: String
    public var category: VaultCategory
    public var fileURL: URL?
    public var secretNote: String?
    public var dateAdded: Date

    public init(id: UUID = UUID(), name: String, category: VaultCategory, fileURL: URL? = nil, secretNote: String? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.fileURL = fileURL
        self.secretNote = secretNote
        self.dateAdded = dateAdded
    }
}
