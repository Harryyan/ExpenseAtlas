import Observation
import Foundation

@MainActor
@Observable
final class AtlasViewModel {
    func sumByCategory(_ txs: [Transaction]) -> [(CategoryEntity, Decimal)] {
        var dict: [CategoryEntity: Decimal] = [:]
        
        for tx in txs where tx.direction == .debit {
            dict[tx.category, default: 0] += tx.amount
        }
        return dict.sorted { $0.key.displayName < $1.key.displayName }
            .map { ($0.key, $0.value) }
    }

    func totalSpend(_ txs: [Transaction]) -> Decimal {
        txs
            .filter { $0.direction == .debit }
            .reduce(0) { $0 + $1.amount }
    }
}
