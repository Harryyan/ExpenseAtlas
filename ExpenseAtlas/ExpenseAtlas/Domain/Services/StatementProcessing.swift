import Foundation
import SwiftData

protocol StatementProcessing {
    func generateTransactions(for doc: StatementDoc) async throws -> [Transaction]
}

struct DemoStatementProcessor: StatementProcessing {
    
    func generateTransactions(for doc: StatementDoc) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 150_000_000)
        
        return [
            Transaction(
                date: .now,
                amount: 25.40,
                currency: "USD",
                direction: .debit,
                rawDescription: "STARBUCKS",
                merchant: "Starbucks",
                category: .dining,
                document: doc
            ),
            Transaction(
                date: .now.addingTimeInterval(-86400),
                amount: 79.00,
                currency: "USD",
                direction: .debit,
                rawDescription: "AMAZON MARKETPLACE",
                merchant: "Amazon",
                category: .shopping,
                document: doc
            )
        ]
    }
}
