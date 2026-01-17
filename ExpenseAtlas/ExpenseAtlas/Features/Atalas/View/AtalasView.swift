import SwiftUI

struct AtlasView: View {
    let doc: StatementDoc
    @State var vm: AtlasViewModel

    var body: some View {
        let byCategory = vm.sumByCategory(doc.transactions)
        let total = vm.totalSpend(doc.transactions)

        return List {
            Section("Summary") {
                Text("Transactions: \(doc.transactions.count)")
                Text("Total spend: \(total)")
                if let t = doc.lastAnalyzedAt {
                    Text("Last analyzed: \(t.formatted())")
                }
            }

            Section("Spend by Category") {
                if byCategory.isEmpty {
                    Text("No spend data yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(byCategory.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.0.displayName)
                            Spacer()
                            Text("\(item.1)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Transactions") {
                ForEach(doc.transactions) { tx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tx.rawDescription)
                        Text("\(tx.direction.rawValue) \(tx.amount) \(tx.currency) • \(tx.category.displayName)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
