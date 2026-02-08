import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEnvironment.self) private var env
    
    @AppStorage("folderSortMode") private var folderSortMode = RootViewModel.FolderSortMode.nameAsc
    
    @State var vm: RootViewModel
    
    @Query private var folders: [Folder]
    @Query private var allDocs: [StatementDoc]
    
    var body: some View {
        let displayFolders = vm.sortedFolders(folders, mode: folderSortMode)
        let selectedFolder = vm.selectedFolder(from: folders)
        let selectedDoc = vm.selectedDoc(from: allDocs)

        let folderCounts = Dictionary(uniqueKeysWithValues: folders.map { folder in
            (folder.id, vm.documentCount(for: folder, allDocs: allDocs))
        })
        let allFilesCount = vm.documentCount(for: nil, allDocs: allDocs)

        NavigationSplitView(columnVisibility: $vm.columnVisibility, preferredCompactColumn: .constant(.content)) {
            FolderSidebarView(
                folders: displayFolders,
                folderCounts: folderCounts,
                allFilesCount: allFilesCount,
                selection: $vm.selectedFolderID,
                sortMode: folderSortMode,
                onChangeSortMode: { folderSortMode = $0 },
                onCreateFolder: { name in
                    vm.createFolder(with: name, context: context)
                },
                onDeleteFolder: { folder in
                    vm.deleteFolder(folder, context: context)
                }
            )
        } content: {
            DocumentListView(
                vm: env.library.makeDocumentListViewModel(folder: selectedFolder),
                selection: $vm.selectedDocID,
                onImport: { urls in
                    vm.importDocs(urls, into: selectedFolder, context: context)
                }
            )
            .id(vm.selectedFolderID)
            .onChange(of: vm.selectedFolderID) { _, _ in
                vm.selectedDocID = nil
            }
        } detail: {
            DetailView(doc: selectedDoc, vm: env.detail.makeDetailViewModel())
        }
        .navigationSplitViewStyle(.balanced)
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            //            Text(vm.errorMessage ?? "Unknown error")
        }
    }
}
