import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RootViewModel {
    // UI State
    var selectedFolderID: UUID?
    var selectedDocID: UUID?
    var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    // Error state
    var showError: Bool = false
    var errorMsg: String?
    
    let folderUseCase: FolderUseCase
    let statementUseCase: StatementUseCase
    
    @AppStorage("folderSortMode") var folderSortMode: FolderSortMode = .nameAsc
    
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
    }
    
    // MARK: - Read helpers
    func sortedFolders(_ folders: [Folder]) -> [Folder] {
        switch folderSortMode {
        case .nameAsc:
             folders.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .updatedDesc:
             folders.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    func selectedFolder(from folders: [Folder]) -> Folder? {
        folders.first { $0.id == selectedFolderID }
    }
    
    func docs(with folderID: UUID?, allDocs: [StatementDoc]) -> [StatementDoc] {
        guard let folderID else { return allDocs }
        
        return allDocs.filter { $0.folder?.id == folderID }
    }
    
    func selectedDoc(from docs: [StatementDoc]) -> StatementDoc? {
        docs.first { $0.id == selectedDocID }
    }
    
    // MARK: - Actions(TBC)
}
