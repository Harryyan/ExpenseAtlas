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
    
}
