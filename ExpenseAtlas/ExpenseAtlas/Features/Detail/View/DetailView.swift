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
                vm.generate(doc: doc, context: context)
            } label: {
                Label("Generate", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(doc.status == .processing)
        }
        .padding()
    }
}
