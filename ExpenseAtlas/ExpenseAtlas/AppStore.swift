import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AppStore {

    func createFolder(name: String, context: ModelContext) {
        let folder = Folder(name: name)
        context.insert(folder)
        try? context.save()
    }

    func importDocs(_ urls: [URL], into folder: Folder?, context: ModelContext) {
        for url in urls {
            let fileName = url.lastPathComponent
            let title = url.deletingPathExtension().lastPathComponent
            let type = FileType(ext: url.pathExtension)

            // TODO: 生产里复制到 App 容器后再写 relative path
            let placeholderLocalPath = "statements/\(UUID().uuidString).\(url.pathExtension)"

            let doc = StatementDoc(
                title: title,
                originalFileName: fileName,
                fileType: type,
                localFilePath: placeholderLocalPath,
                fileSize: 0,
                folder: folder
            )
            context.insert(doc)
        }
        try? context.save()
    }

    func deleteFolder(_ folder: Folder, context: ModelContext) {
        context.delete(folder) // nullify docs.folder
        try? context.save()
    }

    func deleteDoc(_ doc: StatementDoc, context: ModelContext) {
        context.delete(doc) // cascade transactions
        try? context.save()
    }

    func generateInsights(for doc: StatementDoc, context: ModelContext) {
        doc.status = .processing
        try? context.save()

        doc.transactions.removeAll()

        let t1 = Transaction(
            date: .now,
            amount: 25.40,
            currency: "USD",
            direction: .debit,
            rawDescription: "STARBUCKS",
            merchant: "Starbucks",
            category: .dining,
            document: doc
        )

        let t2 = Transaction(
            date: .now.addingTimeInterval(-86400),
            amount: 79.00,
            currency: "USD",
            direction: .debit,
            rawDescription: "AMAZON MARKETPLACE",
            merchant: "Amazon",
            category: .shopping,
            document: doc
        )

        doc.transactions.append(contentsOf: [t1, t2])
        doc.status = .done
        doc.lastAnalyzedAt = .now
        try? context.save()
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
