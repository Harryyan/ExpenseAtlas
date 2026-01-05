import Foundation
import SwiftData

@Model
final class StatementDoc {
    @Attribute(.unique) var id: UUID
    
    // MARK: - Basic Info
    
    var title: String
    var originalFileName: String
    var fileType: FileType
    var importedAt: Date
    
    // MARK: - File Storage
    
    var localFilePath: String          // App container relative path
    var fileSize: Int64
    
    // MARK: - Analysis State
    
    var status: Status                 // idle / processing / done / failed
    var lastAnalyzedAt: Date?
    var errorMessage: String?
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]

    @Relationship
    var folder: Folder?
    
    // MARK: - Init
    
    init(
        title: String,
        originalFileName: String,
        fileType: FileType,
        localFilePath: String,
        fileSize: Int64,
        folder: Folder?
    ) {
        self.id = UUID()
        self.title = title
        self.originalFileName = originalFileName
        self.fileType = fileType
        self.localFilePath = localFilePath
        self.fileSize = fileSize
        self.folder = folder
        
        self.importedAt = .now
        self.status = .idle
        self.transactions = []
    }
}

enum FileType: String, Codable, CaseIterable {
    case pdf
    case csv
    case unknown
}

enum Status: String, Codable, CaseIterable {
    case idle        // imported but not analyzed
    case processing
    case done
    case failed
}

extension StatementDoc {
    var subtitle: String {
        switch status {
        case .idle:
            return "Not analyzed"
        case .processing:
            return "Analyzing…"
        case .done:
            return "\(transactions.count) transactions"
        case .failed:
            return errorMessage ?? "Failed"
        }
    }
}
