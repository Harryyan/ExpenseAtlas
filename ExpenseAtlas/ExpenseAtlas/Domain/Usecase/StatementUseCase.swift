import Foundation
import SwiftData

protocol StatementUseCase {
    func importDocs(urls: [URL], folder: Folder?, context: ModelContext) throws
    func deleteDoc(_ doc: StatementDoc, context: ModelContext) throws
    func generateInsights(for doc: StatementDoc, context: ModelContext) async throws
}

struct StatementUseCaseImpl: StatementUseCase {
    let statementRepo: StatementRepository
    let folderRepo: FolderRepository
    let processor: StatementProcessing

    func importDocs(urls: [URL], folder: Folder?, context: ModelContext) throws {
        try statementRepo.importDocs(urls, into: folder, context: context)
        if let folder { try folderRepo.touch(folder, context: context) }
    }

    func deleteDoc(_ doc: StatementDoc, context: ModelContext) throws {
        let folder = doc.folder
        try statementRepo.deleteDoc(doc, context: context)
        if let folder { try folderRepo.touch(folder, context: context) }
    }

    func generateInsights(for doc: StatementDoc, context: ModelContext) async throws {
        try statementRepo.updateDocStatus(doc, status: .processing, error: nil, context: context)

        do {
            let txs = try await processor.generateTransactions(for: doc)

            doc.transactions.removeAll()
            doc.transactions.append(contentsOf: txs)
            doc.transactions.forEach { $0.document = doc }

            try statementRepo.updateDocStatus(doc, status: .done, error: nil, context: context)
            try statementRepo.setLastAnalyzed(doc, date: Date(), context: context)

            if let folder = doc.folder {
                try folderRepo.touch(folder, context: context)
            }
        } catch {
            try statementRepo.updateDocStatus(doc, status: .failed, error: String(describing: error), context: context)
            throw error
        }
    }
}
