import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    
    // MARK: - Core Fields
    
    var date: Date
    var amount: Decimal
    var currency: String             // "NZD", "CNY", "USD"
    var direction: Direction         // debit / credit
    
    // MARK: - Description
    
    var rawDescription: String
    var merchant: String?            // merchant name
    
    // MARK: - Categorization
    
    var category: Category
    var isUserEdited: Bool           // if edited category manaully
    
    // MARK: - Optional Financial Info
    
    var balance: Decimal?
    var reference: String?
    
    // MARK: - Metadata
    
    var createdAt: Date
    var sourceLine: String?
    
    // MARK: - Relationships
    
    @Relationship(inverse: \StatementDoc.transactions)
    var document: StatementDoc?
    
    // MARK: - Init
    
    init(
        date: Date,
        amount: Decimal,
        currency: String,
        direction: Direction,
        rawDescription: String,
        merchant: String? = nil,
        category: Category = .unknown,
        isUserEdited: Bool = false,
        balance: Decimal? = nil,
        reference: String? = nil,
        sourceLine: String? = nil,
        document: StatementDoc?
    ) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.currency = currency
        self.direction = direction
        self.rawDescription = rawDescription
        self.merchant = merchant
        self.category = category
        self.isUserEdited = isUserEdited
        self.balance = balance
        self.reference = reference
        self.sourceLine = sourceLine
        self.document = document
        self.createdAt = .now
    }
}

enum Direction: String, Codable, CaseIterable {
    case debit
    case credit
}
