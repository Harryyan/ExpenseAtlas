import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEnvironment.self) private var env
    
    let doc: StatementDoc?
    @State var vm: DetailViewModel
    
    var body: some View {
        if let doc {
            VStack(spacing: 0) {
                header(doc)
                Divider()
                
                TabView {
                    OriginalPreviewView(doc: doc)
                        .tabItem { Label("Original", systemImage: "doc.text") }
                    
                    //                    AtlasEntryView(doc: doc)
                    //                        .tabItem { Label("Atlas", systemImage: "chart.pie") }
                }
            }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
        } else {
            ContentUnavailableView(
                "Select a statement",
                systemImage: "doc",
                description: Text("Choose a file to preview and generate insights.")
            )
        }
    }
    
    private func header(_ doc: StatementDoc) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title).font(.headline)
                if doc.status == .processing {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Analyzing…").foregroundStyle(.secondary)
                    }
                } else {
                    Text(doc.subtitle).foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                Task { await vm.generate(doc: doc, context: context) }
            } label: {
                Label("Generate", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(doc.status == .processing)
        }
        .padding()
    }
}

struct OriginalPreviewView: View {
    let doc: StatementDoc
    var body: some View {
        List {
            LabeledContent("File", value: doc.originalFileName)
            LabeledContent("Type", value: doc.fileType.rawValue.uppercased())
            LabeledContent("Status", value: doc.status.rawValue)
            LabeledContent("Imported", value: doc.importedAt.formatted())
        }
    }
}
