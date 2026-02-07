import Observation
import Foundation

@MainActor
@Observable
final class AtlasViewModel {
    private let doc: StatementDoc

    init(doc: StatementDoc) {
        self.doc = doc
    }

    var transactionCount: Int { doc.transactions.count }
    var lastAnalyzedAt: Date? { doc.lastAnalyzedAt }
    var transactions: [Transaction] { doc.transactions }

    var categoryBreakdown: [(CategoryEntity, Decimal)] {
        var dict: [CategoryEntity: Decimal] = [:]

        for tx in doc.transactions where tx.direction == .debit {
            dict[tx.category, default: 0] += tx.amount
        }
        return dict.sorted { $0.key.displayName < $1.key.displayName }
            .map { ($0.key, $0.value) }
    }

    var totalSpend: Decimal {
        doc.transactions
            .filter { $0.direction == .debit }
            .reduce(0) { $0 + $1.amount }
    }
}
