import SwiftUI

struct FolderSidebarView: View {
    @State var viewModel: FileSideBarViewModel
    @Binding var selection: UUID?

    let onCreateFolder: (String) -> Void
    let onDeleteFolder: (Folder) -> Void

    @State private var showNewFolder = false
    @State private var folderName = ""

    var body: some View {
        List(selection: $selection) {
            ForEach(viewModel.folders) { folder in
                Label(folder.name, systemImage: "folder")
                    .tag(folder.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteFolder()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New Folder", isPresented: $showNewFolder) {
            TextField("Name", text: $folderName)
            Button("Create") {
                let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { viewModel.createFolder(with: name) }
                folderName = ""
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
