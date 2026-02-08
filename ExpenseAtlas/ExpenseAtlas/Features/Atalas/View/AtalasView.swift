import SwiftUI

struct AtlasView: View {
    @State var vm: AtlasViewModel

    var body: some View {
        List {
            Section("Summary") {
                Text("Transactions: \(vm.transactionCount)")
                Text("Total spend: \(vm.totalSpend.formatted())")
                Text("Last analyzed: \(vm.lastAnalyzedAt?.formatted() ?? "N/A")")
                    .opacity(vm.lastAnalyzedAt != nil ? 1 : 0)
            }

            Section("Spend by Category") {
                Text("No spend data yet.")
                    .foregroundStyle(.secondary)
                    .opacity(vm.categoryBreakdown.isEmpty ? 1 : 0)

                ForEach(Array(vm.categoryBreakdown.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.0.displayName)
                        Spacer()
                        Text("\(item.1.formatted())")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Transactions") {
                ForEach(vm.transactions) { tx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tx.rawDescription)
                        Text("\(tx.direction.rawValue) \(tx.amount.formatted()) \(tx.currency) • \(tx.category.displayName)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
