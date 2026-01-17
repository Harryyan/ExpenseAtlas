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
    
    init(folderUseCase: FolderUseCase, statementUseCase: StatementUseCase) {
        self.folderUseCase = folderUseCase
        self.statementUseCase = statementUseCase
    }
}
