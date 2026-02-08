import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEnvironment.self) private var env

    let doc: StatementDoc?
    @State var vm: DetailViewModel
    @State private var selectedTab: DetailTab = .original

    private enum DetailTab: String {
        case original
        case transactions
    }

    var body: some View {
        if let doc {
            VStack(spacing: 0) {
                header(doc)
                Divider()

                TabView(selection: $selectedTab) {
                    OriginalPreviewView(doc: doc)
                        .tabItem { Label("Original", systemImage: "doc.text") }
                        .tag(DetailTab.original)

                    TransactionsListView(transactions: doc.transactions)
                        .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
                        .tag(DetailTab.transactions)
                }
                .onChange(of: vm.shouldSwitchToTransactions) { _, shouldSwitch in
                    if shouldSwitch {
                        selectedTab = .transactions
                        vm.shouldSwitchToTransactions = false
                    }
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

            if vm.isCategorizing {
                VStack(spacing: 4) {
                    ProgressView(value: vm.categorizationProgress)
                        .frame(width: 100)
                    Text("\(Int(vm.categorizationProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                if vm.isCategorizing {
                    vm.cancelCategorization()
                } else {
                    vm.startCategorization(doc: doc, context: context)
                }
            } label: {
                Label(vm.isCategorizing ? "Cancel" : "Categorize", systemImage: vm.isCategorizing ? "xmark.circle" : "tag")
            }
            .buttonStyle(.bordered)
            .disabled(!vm.isModelAvailable && !vm.isCategorizing)

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
