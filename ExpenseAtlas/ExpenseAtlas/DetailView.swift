import SwiftUI

struct DetailView: View {
    let doc: StatementDoc?
    let onGenerate: (StatementDoc) -> Void

    var body: some View {
        if let doc {
            VStack(spacing: 0) {
                header(doc)
                Divider()
                TabView {
                    OriginalPreviewView(doc: doc)
                        .tabItem { Label("Original", systemImage: "doc.text") }

                    ExpenseAtlasView(doc: doc)
                        .tabItem { Label("Atlas", systemImage: "chart.pie") }
                }
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
            Text(doc.title).font(.headline)
            Spacer()
            Button {
                onGenerate(doc)
            } label: {
                Label("Generate", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(doc.status == .processing)
        }
        .padding()
    }
}

// 先给占位视图，后续你可以换成 PDFKit / 表格预览
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

struct ExpenseAtlasView: View {
    let doc: StatementDoc
    var body: some View {
        List {
            Section("Summary") {
                Text("Transactions: \(doc.transactions.count)")
                if let t = doc.lastAnalyzedAt {
                    Text("Last analyzed: \(t.formatted())")
                }
            }
            Section("Sample Transactions") {
                ForEach(doc.transactions) { tx in
                    VStack(alignment: .leading) {
                        Text(tx.rawDescription)
                        Text(verbatim: "\(tx.direction.rawValue) \(tx.amount) \(tx.currency) • \(tx.category.displayName)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

