import SwiftUI

struct TransactionsListView: View {
    let transactions: [Transaction]

    var body: some View {
        if transactions.isEmpty {
            ContentUnavailableView(
                "No Transactions",
                systemImage: "tray",
                description: Text("Click 'Generate' to extract transactions from this statement")
            )
        } else {
            List(transactions) { tx in
                TransactionRow(transaction: tx)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(transaction.category.displayName,
                      systemImage: transaction.category.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(transaction.merchant ?? transaction.rawDescription)
                    .font(.headline)
            }

            HStack {
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                Text("•")
                Text(transaction.direction.rawValue.uppercased())
                    .foregroundStyle(transaction.direction == .debit ? .red : .green)
                Text("•")
                Text("\(transaction.amount.description) \(transaction.currency)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
