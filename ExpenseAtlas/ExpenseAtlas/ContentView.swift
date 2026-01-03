import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    @State private var store = AppStore()   // ✅ @Observable 用 @State 持有
    
    @Query(sort: \Folder.createdAt, order: .forward)
    private var folders: [Folder]
    
    @Query(sort: \StatementDoc.importedAt, order: .reverse)
    private var allDocs: [StatementDoc]
    
    @State private var selectedFolderID: UUID?
    @State private var selectedDocID: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FolderSidebarView(
                folders: folders,
                selection: $selectedFolderID,
                onCreateFolder: { name in
                    store.createFolder(name: name, context: context)
                },
                onDeleteFolder: { folder in
                    store.deleteFolder(folder, context: context)
                    if selectedFolderID == folder.id { selectedFolderID = nil }
                }
            )
            
        } content: {
            DocumentListView(
                folder: selectedFolder,
                docs: docsInSelectedFolder,
                selection: $selectedDocID,
                onImport: { urls in
                    store.importDocs(urls, into: selectedFolder, context: context)
                },
                onDeleteDoc: { doc in
                    store.deleteDoc(doc, context: context)
                    if selectedDocID == doc.id { selectedDocID = nil }
                }
            )
            .onChange(of: selectedFolderID) { _, _ in selectedDocID = nil }
        } detail: {
            DetailView(
                doc: selectedDoc,
                onGenerate: { doc in
                    store.generateInsights(for: doc, context: context)
                }
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var selectedFolder: Folder? {
        folders.first { $0.id == selectedFolderID }
    }
    
    private var docsInSelectedFolder: [StatementDoc] {
        guard let folderID = selectedFolderID else {
            // “未分类”或全部：这里先显示全部；你也可以只显示 folder == nil
            return allDocs
        }
        return allDocs.filter { $0.folder?.id == folderID }
    }
    
    private var selectedDoc: StatementDoc? {
        allDocs.first { $0.id == selectedDocID }
    }
}
