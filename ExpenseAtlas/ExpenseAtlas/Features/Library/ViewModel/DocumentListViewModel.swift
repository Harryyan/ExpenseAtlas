import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class DocumentListViewModel {
    private let folder: Folder?
    private let folderID: UUID?
    private let statementUseCase: StatementUseCase

    var showError: Bool = false
    var errorMessage: String?

    init(folder: Folder?, statementUseCase: StatementUseCase) {
        self.folder = folder
        self.folderID = folder?.id
        self.statementUseCase = statementUseCase
    }

    func filterDocuments(_ allDocs: [StatementDoc]) -> [StatementDoc] {
        guard let folderID else { return allDocs }
        return allDocs.filter { $0.folder?.id == folderID }
    }

    var navigationTitle: String {
        folder?.name ?? "All Files"
    }

    func deleteDocument(_ doc: StatementDoc, context: ModelContext) {
        do {
            try statementUseCase.deleteDoc(doc, context: context)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
