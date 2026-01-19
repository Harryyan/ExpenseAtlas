import Foundation
import SwiftData

enum FileType: String, Codable, CaseIterable { case pdf, csv, ofx, qif, unknown }
enum DocStatus: String, Codable, CaseIterable { case idle, processing, done, failed }

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
    var status: DocStatus
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

extension StatementDoc {
    var subtitle: String {
        switch status {
        case .idle: return "Not analyzed"
        case .processing: return "Analyzing…"
        case .done: return "\(transactions.count) transactions"
        case .failed: return errorMessage ?? "Failed"
        }
    }

    /// Base directory for storing imported statement files
    static var statementsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Statements", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Full URL to the stored file
    var fileURL: URL? {
        guard !localFilePath.isEmpty else { return nil }
        return Self.statementsDirectory.appendingPathComponent(localFilePath)
    }
}
