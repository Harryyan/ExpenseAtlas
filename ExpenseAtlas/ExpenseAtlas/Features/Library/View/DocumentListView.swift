import SwiftUI
import UniformTypeIdentifiers

struct DocumentListView: View {
    let folder: Folder?
    let docs: [StatementDoc]
    @Binding var selection: UUID?
    
    let onImport: ([URL]) -> Void
    let onDeleteDoc: (StatementDoc) -> Void
    
    @State private var showImporter = false
    @State private var isDropTarget = false
    
    var body: some View {
        List(selection: $selection) {
            ForEach(docs) { doc in
                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.title).font(.headline)
                    Text(doc.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                .tag(doc.id)
                .contextMenu {
                    Button(role: .destructive) { onDeleteDoc(doc) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(folder?.name ?? "Statements")
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button { showImporter = true } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            #endif
        }
        #if os(macOS)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.pdf, .commaSeparatedText, .plainText],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result { onImport(urls) }
        }
        #endif
        .overlay {
            if docs.isEmpty {
                #if os(macOS)
                VStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.down").font(.system(size: 36))
                    Text("Drag & Drop statements here")
                    Text("or import PDF/CSV").foregroundStyle(.secondary)
                }
                .padding(24)
                .background(.thinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDropTarget ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                )
                .padding()
                #else
                VStack(spacing: 10) {
                    Image(systemName: "clock").font(.system(size: 36))
                    Text("Import Coming Soon")
                    Text("Share files from other apps").foregroundStyle(.secondary)
                }
                .padding(24)
                .background(.thinMaterial)
                .cornerRadius(16)
                .padding()
                #endif
            }
        }
        #if os(macOS)
        .dropDestination(for: URL.self) { urls, _ in
            onImport(urls)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
        #endif
    }
}
