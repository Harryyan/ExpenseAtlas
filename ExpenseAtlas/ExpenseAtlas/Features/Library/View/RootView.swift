import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEnvironment.self) private var env
    
    @State private var vm: RootViewModel
    
    @Query private var folders: [Folder]
    @Query private var allDocs: [StatementDoc]
    
    var body: some View {
        let displayFolders = vm.sortedFolders(folders)
        let selectedFolder = vm.selectedFolder(from: folders)
        let docs = vm.docs(with: vm.selectedFolderID, allDocs: allDocs)
        let selectedDoc = vm.selectedDoc(from: allDocs)
        
        NavigationSplitView(columnVisibility: $vm.columnVisibility, preferredCompactColumn: .constant(.content)) {
            FolderSidebarView(
                folders: displayFolders,
                selection: $vm.selectedFolderID,
                sortMode: vm.folderSortMode,
                onChangeSortMode: { vm.folderSortMode = $0 },
                onCreateFolder: { name in
                    //                               vm.createFolder(name: name, existingFolders: folders, context: context)
                },
                onDeleteFolder: { folder in
                    //                               vm.deleteFolder(folder, context: context)
                }
            )
        } content: {
            DocumentListView(
                folder: selectedFolder,
                docs: docs,
                selection: $vm.selectedDocID,
                onImport: { urls in
                    //                                vm.importDocs(urls, into: selectedFolder, context: context)
                },
                onDeleteDoc: { doc in
                    //                                vm.deleteDoc(doc, context: context)
                }
            )
            .onChange(of: vm.selectedFolderID) { _, _ in
                vm.selectedDocID = nil
            }
        } detail: {
            DetailView(doc: nil) { doc in
                
            }
        }
        .navigationSplitViewStyle(.balanced)
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            //            Text(vm.errorMessage ?? "Unknown error")
        }
    }
}
