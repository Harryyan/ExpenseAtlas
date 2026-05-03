import Foundation

struct MonthlyExpenseReport: Identifiable, Equatable {
    let monthStart: Date
    let monthTitle: String
    let currencyCode: String
    let currencies: [String]
    let transactionCount: Int
    let debitTransactionCount: Int
    let creditTransactionCount: Int
    let totalSpent: Decimal
    let totalIncome: Decimal
    let netCashFlow: Decimal
    let averageDailySpend: Decimal
    let categoryBreakdown: [CategoryExpense]
    let merchantBreakdown: [MerchantExpense]
    let dailySpend: [DailyExpense]
    let largestTransactions: [TransactionSnapshot]

    var id: Date { monthStart }
    var hasMixedCurrencies: Bool { currencies.count > 1 }
}

struct CategoryExpense: Identifiable, Equatable {
    let category: CategoryEntity
    let amount: Decimal
    let transactionCount: Int
    let percentage: Double

    var id: CategoryEntity { category }
}

struct MerchantExpense: Identifiable, Equatable {
    let merchant: String
    let amount: Decimal
    let transactionCount: Int
    let percentage: Double

    var id: String { merchant }
}

struct DailyExpense: Identifiable, Equatable {
    let date: Date
    let amount: Decimal

    var id: Date { date }
}

struct TransactionSnapshot: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let amount: Decimal
    let currency: String
    let direction: Direction
    let description: String
    let merchant: String?
    let category: CategoryEntity
}

enum MonthlyExpenseReportBuilder {
    static func reports(from transactions: [Transaction], calendar: Calendar = .current) -> [MonthlyExpenseReport] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            monthStart(for: transaction.date, calendar: calendar)
        }

        return grouped
            .map { monthStart, transactions in
                makeReport(monthStart: monthStart, transactions: transactions, calendar: calendar)
            }
            .sorted { $0.monthStart > $1.monthStart }
    }

    static func makeReport(
        monthStart: Date,
        transactions: [Transaction],
        calendar: Calendar = .current
    ) -> MonthlyExpenseReport {
        let debitTransactions = transactions.filter { $0.direction == .debit }
        let creditTransactions = transactions.filter { $0.direction == .credit }
        let totalSpent = debitTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        let totalIncome = creditTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 1
        let averageDailySpend = totalSpent / Decimal(daysInMonth)
        let currencies = sortedCurrencies(from: transactions)
        let currencyCode = primaryCurrency(from: transactions)

        return MonthlyExpenseReport(
            monthStart: monthStart,
            monthTitle: monthTitle(for: monthStart),
            currencyCode: currencyCode,
            currencies: currencies,
            transactionCount: transactions.count,
            debitTransactionCount: debitTransactions.count,
            creditTransactionCount: creditTransactions.count,
            totalSpent: totalSpent,
            totalIncome: totalIncome,
            netCashFlow: totalIncome - totalSpent,
            averageDailySpend: averageDailySpend,
            categoryBreakdown: categoryBreakdown(from: debitTransactions, totalSpent: totalSpent),
            merchantBreakdown: merchantBreakdown(from: debitTransactions, totalSpent: totalSpent),
            dailySpend: dailySpend(from: debitTransactions, calendar: calendar),
            largestTransactions: largestTransactions(from: debitTransactions)
        )
    }

    private static func monthStart(for date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private static func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func sortedCurrencies(from transactions: [Transaction]) -> [String] {
        Array(Set(transactions.map { $0.currency.uppercased() })).sorted()
    }

    private static func primaryCurrency(from transactions: [Transaction]) -> String {
        let counts = Dictionary(grouping: transactions.map { $0.currency.uppercased() }, by: { $0 })
            .mapValues(\.count)

        return counts.max {
            if $0.value == $1.value {
                return $0.key > $1.key
            }
            return $0.value < $1.value
        }?.key ?? "NZD"
    }

    private static func categoryBreakdown(from transactions: [Transaction], totalSpent: Decimal) -> [CategoryExpense] {
        let grouped = Dictionary(grouping: transactions, by: \.category)

        return grouped.map { category, transactions in
            let amount = transactions.reduce(Decimal.zero) { $0 + $1.amount }
            return CategoryExpense(
                category: category,
                amount: amount,
                transactionCount: transactions.count,
                percentage: percentage(amount, of: totalSpent)
            )
        }
        .sorted {
            if $0.amount == $1.amount {
                return $0.category.displayName < $1.category.displayName
            }
            return $0.amount > $1.amount
        }
    }

    private static func merchantBreakdown(from transactions: [Transaction], totalSpent: Decimal) -> [MerchantExpense] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            let merchant = transaction.merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
            return merchant?.isEmpty == false ? merchant! : transaction.rawDescription
        }

        return grouped.map { merchant, transactions in
            let amount = transactions.reduce(Decimal.zero) { $0 + $1.amount }
            return MerchantExpense(
                merchant: merchant,
                amount: amount,
                transactionCount: transactions.count,
                percentage: percentage(amount, of: totalSpent)
            )
        }
        .sorted {
            if $0.amount == $1.amount {
                return $0.merchant < $1.merchant
            }
            return $0.amount > $1.amount
        }
        .prefix(8)
        .map { $0 }
    }

    private static func dailySpend(from transactions: [Transaction], calendar: Calendar) -> [DailyExpense] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return grouped
            .map { date, transactions in
                DailyExpense(date: date, amount: transactions.reduce(Decimal.zero) { $0 + $1.amount })
            }
            .sorted { $0.date < $1.date }
    }

    private static func largestTransactions(from transactions: [Transaction]) -> [TransactionSnapshot] {
        transactions
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map {
                TransactionSnapshot(
                    id: $0.id,
                    date: $0.date,
                    amount: $0.amount,
                    currency: $0.currency,
                    direction: $0.direction,
                    description: $0.rawDescription,
                    merchant: $0.merchant,
                    category: $0.category
                )
            }
    }

    private static func percentage(_ amount: Decimal, of total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        return (amount as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue
    }
}
