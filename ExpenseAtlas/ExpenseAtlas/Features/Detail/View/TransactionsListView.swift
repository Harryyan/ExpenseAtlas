import SwiftUI

struct TransactionsListView: View {
    let transactions: [Transaction]

    var body: some View {
        let sortedTransactions = sorted(transactions)

        if sortedTransactions.isEmpty {
            ContentUnavailableView(
                "No Transactions",
                systemImage: "tray",
                description: Text("Click 'Generate' to extract transactions from this statement")
            )
        } else {
            List(sortedTransactions) { tx in
                TransactionRow(transaction: tx)
            }
        }
    }

    private func sorted(_ transactions: [Transaction]) -> [Transaction] {
        transactions.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.date == rhs.element.date {
                    return lhs.offset < rhs.offset
                }
                return lhs.element.date > rhs.element.date
            }
            .map { $0.element }
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
                Text(transaction.rawDescription)
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack {
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                Text("•")
                Text(transaction.direction.rawValue.uppercased())
                    .foregroundStyle(transaction.direction == .debit ? .red : .green)
                Text("•")
                Text(formatAmount(transaction.amount, currency: transaction.currency))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatAmount(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let symbol = currencySymbol(for: currency)

        if let formatted = formatter.string(from: amount as NSDecimalNumber) {
            return "\(symbol)\(formatted)"
        }
        return "\(symbol)\(amount)"
    }

    private func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD", "NZD", "AUD", "CAD", "SGD", "HKD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "JPY", "CNY":
            return "¥"
        case "CHF":
            return "Fr"
        case "INR":
            return "₹"
        default:
            return "$"
        }
    }
}
