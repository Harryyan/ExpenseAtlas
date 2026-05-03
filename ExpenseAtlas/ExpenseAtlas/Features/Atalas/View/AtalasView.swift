import Charts
import SwiftUI

struct AtlasView: View {
    @State var vm: AtlasViewModel

    var body: some View {
        if let report = vm.selectedReport {
            List {
                Section {
                    if vm.monthlyReports.count > 1 {
                        Picker("Month", selection: $vm.selectedMonthStart) {
                            ForEach(vm.monthlyReports) { report in
                                Text(report.monthTitle).tag(Optional(report.monthStart))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    ReportSummaryGrid(report: report)

                    if report.hasMixedCurrencies {
                        Label("Mixed currencies: \(report.currencies.joined(separator: ", "))", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Daily Spend") {
                    if report.dailySpend.isEmpty {
                        Text("No spending for this month.")
                            .foregroundStyle(.secondary)
                    } else {
                        DailySpendChart(report: report)
                            .frame(height: 180)
                            .padding(.vertical, 8)
                    }
                }

                Section("Spend by Category") {
                    if report.categoryBreakdown.isEmpty {
                        Text("No categorized spending yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(report.categoryBreakdown) { item in
                            CategoryExpenseRow(item: item, currencyCode: report.currencyCode)
                        }
                    }
                }

                Section("Top Merchants") {
                    if report.merchantBreakdown.isEmpty {
                        Text("No merchant spending yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(report.merchantBreakdown) { item in
                            MerchantExpenseRow(item: item, currencyCode: report.currencyCode)
                        }
                    }
                }

                Section("Largest Transactions") {
                    ForEach(report.largestTransactions) { transaction in
                        SnapshotTransactionRow(transaction: transaction)
                    }
                }
            }
            .navigationTitle(report.monthTitle)
        } else {
            ContentUnavailableView(
                "No Report",
                systemImage: "chart.pie",
                description: Text("Generate transactions to see monthly spending.")
            )
        }
    }
}

private struct ReportSummaryGrid: View {
    let report: MonthlyExpenseReport

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                SummaryMetric(title: "Spent", value: formatAmount(report.totalSpent, currency: report.currencyCode), systemImage: "arrow.up.right")
                SummaryMetric(title: "Income", value: formatAmount(report.totalIncome, currency: report.currencyCode), systemImage: "arrow.down.left")
            }

            GridRow {
                SummaryMetric(title: "Net", value: formatSignedAmount(report.netCashFlow, currency: report.currencyCode), systemImage: "equal")
                SummaryMetric(title: "Daily Avg", value: formatAmount(report.averageDailySpend, currency: report.currencyCode), systemImage: "calendar")
            }

            GridRow {
                SummaryMetric(title: "Transactions", value: "\(report.transactionCount)", systemImage: "list.bullet.rectangle")
                SummaryMetric(title: "Debits", value: "\(report.debitTransactionCount)", systemImage: "minus.circle")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private struct DailySpendChart: View {
    let report: MonthlyExpenseReport

    var body: some View {
        Chart(report.dailySpend) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Spend", decimalValue(item.amount))
            )
            .foregroundStyle(.blue)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

private struct CategoryExpenseRow: View {
    let item: CategoryExpense
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(item.category.displayName, systemImage: item.category.systemImage)
                Spacer()
                Text(formatAmount(item.amount, currency: currencyCode))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: item.percentage)

            HStack {
                Text("\(item.transactionCount) transactions")
                Spacer()
                Text(item.percentage, format: .percent.precision(.fractionLength(1)))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct MerchantExpenseRow: View {
    let item: MerchantExpense
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.merchant)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(item.transactionCount) transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(item.amount, currency: currencyCode))
                    .monospacedDigit()
                Text(item.percentage, format: .percent.precision(.fractionLength(1)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SnapshotTransactionRow: View {
    let transaction: TransactionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.merchant ?? transaction.description)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(formatAmount(transaction.amount, currency: transaction.currency))
                    .monospacedDigit()
            }

            HStack {
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                Text(transaction.category.displayName)
                Text(transaction.direction.rawValue.uppercased())
                    .foregroundStyle(transaction.direction == .debit ? .red : .green)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private func decimalValue(_ amount: Decimal) -> Double {
    (amount as NSDecimalNumber).doubleValue
}

private func formatAmount(_ amount: Decimal, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2

    return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
}

private func formatSignedAmount(_ amount: Decimal, currency: String) -> String {
    let sign = amount >= 0 ? "+" : "-"
    let magnitude = amount >= 0 ? amount : -amount
    return "\(sign)\(formatAmount(magnitude, currency: currency))"
}
