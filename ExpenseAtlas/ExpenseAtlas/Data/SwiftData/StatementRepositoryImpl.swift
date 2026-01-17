import Foundation
import SwiftData

struct StatementRepositoryImpl: StatementRepository {
    
    func importDocs(_ urls: [URL], into folder: Folder?, context: ModelContext) throws {
        for url in urls {
            let originalFileName = url.lastPathComponent
            let title = url.deletingPathExtension().lastPathComponent
            let type = FileType(ext: url.pathExtension)

            let placeholderLocalPath = "statements/\(UUID().uuidString).\(url.pathExtension)"

            let doc = StatementDoc(
                title: title,
                originalFileName: originalFileName,
                fileType: type,
                localFilePath: placeholderLocalPath,
                fileSize: 0,
                folder: folder
            )
            context.insert(doc)
        }
        try context.save()
    }

    func deleteDoc(_ doc: StatementDoc, context: ModelContext) throws {
        context.delete(doc)
        try context.save()
    }

    func updateDocStatus(_ doc: StatementDoc, status: DocStatus, error: String?, context: ModelContext) throws {
        doc.status = status
        doc.errorMessage = error
        try context.save()
    }

    func setLastAnalyzed(_ doc: StatementDoc, date: Date, context: ModelContext) throws {
        doc.lastAnalyzedAt = date
        try context.save()
    }
}

private extension FileType {
    init(ext: String) {
        switch ext.lowercased() {
        case "pdf": self = .pdf
        case "csv": self = .csv
        case "ofx": self = .ofx
        case "qif": self = .qif
        default: self = .unknown
        }
    }
}
