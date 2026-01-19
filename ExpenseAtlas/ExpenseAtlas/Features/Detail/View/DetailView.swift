import SwiftUI
import SwiftData
import PDFKit

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
        Group {
            switch doc.fileType {
            case .pdf:
                PDFPreviewView(url: doc.fileURL)
            case .csv:
                CSVPreviewView(url: doc.fileURL)
            default:
                FileInfoView(doc: doc)
            }
        }
    }
}

// MARK: - PDF Preview

struct PDFPreviewView: View {
    let url: URL?

    var body: some View {
        if let url, let pdfDocument = PDFDocument(url: url) {
            PDFKitView(document: pdfDocument)
        } else {
            ContentUnavailableView(
                "Unable to load PDF",
                systemImage: "doc.fill",
                description: Text("The file could not be opened.")
            )
        }
    }
}

#if os(macOS)
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}
#else
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}
#endif

// MARK: - CSV Preview

struct CSVPreviewView: View {
    let url: URL?
    @State private var rows: [[String]] = []
    @State private var loadError: String?

    var body: some View {
        Group {
            if let error = loadError {
                ContentUnavailableView(
                    "Unable to load CSV",
                    systemImage: "tablecells",
                    description: Text(error)
                )
            } else if rows.isEmpty {
                ProgressView("Loading...")
            } else {
                CSVTableView(rows: rows)
            }
        }
        .task { loadCSV() }
    }

    private func loadCSV() {
        guard let url else {
            loadError = "File not found"
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            rows = parseCSV(content)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func parseCSV(_ content: String) -> [[String]] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return lines.map { line in
            parseCSVLine(line)
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}

struct CSVTableView: View {
    let rows: [[String]]

    private var headers: [String] {
        rows.first ?? []
    }

    private var dataRows: [[String]] {
        Array(rows.dropFirst())
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(dataRows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(dataRows[rowIndex].indices, id: \.self) { colIndex in
                                Text(dataRows[rowIndex][colIndex])
                                    .frame(minWidth: 100, alignment: .leading)
                                    .padding(8)
                                    .background(rowIndex % 2 == 0 ? Color.clear : Color.secondary.opacity(0.1))
                            }
                        }
                        Divider()
                    }
                } header: {
                    HStack(spacing: 0) {
                        ForEach(headers.indices, id: \.self) { index in
                            Text(headers[index])
                                .font(.headline)
                                .frame(minWidth: 100, alignment: .leading)
                                .padding(8)
                        }
                    }
                    .background(.regularMaterial)
                }
            }
        }
    }
}

// MARK: - Fallback Info View

struct FileInfoView: View {
    let doc: StatementDoc

    var body: some View {
        List {
            LabeledContent("File", value: doc.originalFileName)
            LabeledContent("Type", value: doc.fileType.rawValue.uppercased())
            LabeledContent("Status", value: doc.status.rawValue)
            LabeledContent("Imported", value: doc.importedAt.formatted())
            if doc.fileSize > 0 {
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: doc.fileSize, countStyle: .file))
            }
        }
    }
}
