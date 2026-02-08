//
//  ExtractedTransaction.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation
import FoundationModels

@Generable
struct TransactionExtraction: Codable {
    @Guide(description: "Array of all transactions found in the statement")
    let transactions: [ExtractedTransaction]
}

@Generable
struct ExtractedTransaction: Codable {
    @Guide(description: "Transaction date in format MM/DD/YYYY or DD/MM/YYYY")
    let date: String

    @Guide(description: "Transaction description or merchant name")
    let description: String

    @Guide(description: "Transaction amount as a string, including any negative sign for debits")
    let amount: String

    @Guide(description: "Currency code like USD, NZD, EUR")
    let currency: String?

    @Guide(description: "Transaction type: debit or credit")
    let type: String

    @Guide(description: "Running balance after transaction, if available")
    let balance: String?
}
