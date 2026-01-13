import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var context
    
    // Sorting logic will be handled in VM
    @Query private var folder: [Folder]
    @Query private var allDocs: [StatementDoc]
    
    @State private var viewModel: AppContainerViewModel()
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FolderSidebarView(
                viewModel: FileSideBarViewModel(),
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
