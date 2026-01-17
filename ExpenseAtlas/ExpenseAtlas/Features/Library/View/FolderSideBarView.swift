import SwiftUI

struct FolderSidebarView: View {
    let folders: [Folder]
    @Binding var selection: UUID?

    let sortMode: RootViewModel.FolderSortMode
    let onChangeSortMode: (RootViewModel.FolderSortMode) -> Void

    let onCreateFolder: (String) -> Void
    let onDeleteFolder: (Folder) -> Void

    @State private var showNewFolder = false
    @State private var folderName = ""

    var body: some View {
        List(selection: $selection) {
            ForEach(folders) { folder in
                Label(folder.name, systemImage: "folder")
                    .tag(folder.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteFolder(folder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: Binding(
                        get: { sortMode },
                        set: { onChangeSortMode($0) }
                    )) {
                        ForEach(RootViewModel.FolderSortMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button { showNewFolder = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New Folder", isPresented: $showNewFolder) {
            TextField("Name", text: $folderName)
            Button("Create") {
                let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                onCreateFolder(name)
                folderName = ""
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
