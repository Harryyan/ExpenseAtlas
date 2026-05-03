import Observation
import Foundation

@MainActor
@Observable
final class AtlasViewModel {
    private let doc: StatementDoc
    var selectedMonthStart: Date?

    init(doc: StatementDoc) {
        self.doc = doc
    }

    var transactionCount: Int { doc.transactions.count }
    var lastAnalyzedAt: Date? { doc.lastAnalyzedAt }
    var transactions: [Transaction] { sorted(doc.transactions) }
    var monthlyReports: [MonthlyExpenseReport] {
        MonthlyExpenseReportBuilder.reports(from: doc.transactions)
    }

    var selectedReport: MonthlyExpenseReport? {
        if let selectedMonthStart,
           let report = monthlyReports.first(where: { Calendar.current.isDate($0.monthStart, equalTo: selectedMonthStart, toGranularity: .month) }) {
            return report
        }

        return monthlyReports.first
    }

    var selectedTransactions: [Transaction] {
        guard let report = selectedReport else { return [] }
        return sorted(doc.transactions)
            .filter { Calendar.current.isDate($0.date, equalTo: report.monthStart, toGranularity: .month) }
    }

    var categoryBreakdown: [(CategoryEntity, Decimal)] {
        guard let selectedReport else { return [] }
        return selectedReport.categoryBreakdown.map { ($0.category, $0.amount) }
    }

    var totalSpend: Decimal {
        selectedReport?.totalSpent ?? 0
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
