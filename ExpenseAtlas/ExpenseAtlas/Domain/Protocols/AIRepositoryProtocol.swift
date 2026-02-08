//
//  AIRepositoryProtocol.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation

protocol AIRepositoryProtocol {
    func categorizeTransaction(merchant: String, description: String, amount: Decimal) async -> Result<TransactionCategorization, TransactionError>
    func streamingCategorizeTransactions(_ transactions: [(merchant: String, description: String, amount: Decimal)]) async -> AsyncThrowingStream<TransactionCategorization, Error>
    func generateMonthlyAnalysis(transactions: [(merchant: String, amount: Decimal, category: String, date: Date)], month: Date) async -> Result<MonthlyExpenseAnalysis, TransactionError>
    func extractTransactions(from text: String) async -> Result<[ExtractedTransaction], TransactionError>
    func checkAvailability() -> Bool
    func prewarmModel() async -> Result<Void, TransactionError>
    func resetSession() async -> Result<Void, TransactionError>
}
