import Foundation
import SwiftData

struct StatementRepositoryImpl: StatementRepository {
    
    func importDocs(_ urls: [URL], into folder: Folder?, context: ModelContext) throws {
        let fm = FileManager.default

        for url in urls {
            // Start security-scoped access for files from file picker
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

            let originalFileName = url.lastPathComponent
            let title = url.deletingPathExtension().lastPathComponent
            let type = FileType(ext: url.pathExtension)

            // Generate unique filename and copy to app container
            let storedFileName = "\(UUID().uuidString).\(url.pathExtension)"
            let destinationURL = StatementDoc.statementsDirectory.appendingPathComponent(storedFileName)

            try fm.copyItem(at: url, to: destinationURL)

            let fileSize = (try? fm.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64) ?? 0

            let doc = StatementDoc(
                title: title,
                originalFileName: originalFileName,
                fileType: type,
                localFilePath: storedFileName,
                fileSize: fileSize,
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
