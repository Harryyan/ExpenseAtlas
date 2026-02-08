import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RootViewModel {
    static let allFilesID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    // UI State
    var selectedFolderID: UUID?
    var selectedDocID: UUID?
    var columnVisibility: NavigationSplitViewVisibility = .automatic

    // Error state
    var showError: Bool = false
    var errorMsg: String?

    let folderUseCase: FolderUseCase
    let statementUseCase: StatementUseCase
    
    enum FolderSortMode: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        
        case nameAsc
        case updatedDesc
        
        var title: String {
            switch self {
            case .nameAsc: return "Name (A–Z)"
            case .updatedDesc: return "Recently Updated"
            }
        }
        
        var systemImage: String {
            switch self {
            case .nameAsc: return "textformat"
            case .updatedDesc: return "clock"
            }
        }
    }
    
    init(folderUseCase: FolderUseCase, statementUseCase: StatementUseCase) {
        self.folderUseCase = folderUseCase
        self.statementUseCase = statementUseCase
        self.selectedFolderID = Self.allFilesID
    }
    
    // MARK: - Read helpers
    func sortedFolders(_ folders: [Folder], mode: FolderSortMode) -> [Folder] {
        switch mode {
        case .nameAsc:
            folders.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .updatedDesc:
            folders.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    func selectedFolder(from folders: [Folder]) -> Folder? {
        folders.first { $0.id == selectedFolderID }
    }
    
    var isAllFilesSelected: Bool {
        selectedFolderID == Self.allFilesID
    }

    func docs(with folderID: UUID?, allDocs: [StatementDoc]) -> [StatementDoc] {
        guard let folderID, folderID != Self.allFilesID else { return allDocs }

        return allDocs.filter { $0.folder?.id == folderID }
    }

    func documentCount(for folder: Folder?, allDocs: [StatementDoc]) -> Int {
        guard let folder else { return allDocs.count }
        return allDocs.filter { $0.folder?.id == folder.id }.count
    }
    
    func selectedDoc(from docs: [StatementDoc]) -> StatementDoc? {
        docs.first { $0.id == selectedDocID }
    }
    
    // MARK: - Actions
    func createFolder(with name: String, context: ModelContext) {
        do {
            try folderUseCase.create(name: name, context: context)
        } catch {
            print(error)
        }
    }
    
    func deleteFolder(_ folder: Folder, context: ModelContext) {
        do {
            try folderUseCase.delete(folder, context: context)
        } catch {
            print(error)
        }
    }

    func importDocs(_ urls: [URL], into folder: Folder?, context: ModelContext) {
        let targetFolder = isAllFilesSelected ? nil : folder
        do {
            try statementUseCase.importDocs(urls: urls, folder: targetFolder, context: context)
        } catch {
            errorMsg = error.localizedDescription
            showError = true
        }
    }
}
