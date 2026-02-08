//
//  TransactionCategorizationUseCase.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation
import SwiftData

protocol TransactionCategorizationUseCaseProtocol {
    func categorize(_ transaction: Transaction, context: ModelContext) async -> Result<Void, TransactionError>
    @MainActor func batchCategorize(_ transactions: [Transaction], context: ModelContext) async -> AsyncThrowingStream<Void, Error>
    func generateMonthlyInsights(for month: Date, context: ModelContext) async -> Result<MonthlyExpenseAnalysis, TransactionError>
    func checkModelAvailability() -> Bool
    func prewarmModel() async -> Result<Void, TransactionError>
}

struct TransactionCategorizationUseCaseImpl: TransactionCategorizationUseCaseProtocol {
    let aiRepository: AIRepositoryProtocol

    func categorize(_ transaction: Transaction, context: ModelContext) async -> Result<Void, TransactionError> {
        let result = await aiRepository.categorizeTransaction(
            merchant: transaction.merchant ?? "Unknown",
            description: transaction.rawDescription,
            amount: transaction.amount
        )

        switch result {
        case .success(let categorization):
            // Map string category to CategoryEntity
            if let category = CategoryEntity.from(string: categorization.category) {
                transaction.category = category
                transaction.isUserEdited = false

                do {
                    try context.save()
                    return .success(())
                } catch {
                    return .failure(.categorizationFailed("Failed to save: \(error.localizedDescription)"))
                }
            } else {
                return .failure(.categorizationFailed("Invalid category returned"))
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    @MainActor
    func batchCategorize(_ transactions: [Transaction], context: ModelContext) async -> AsyncThrowingStream<Void, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                let txData = transactions.map { tx in
                    (
                        merchant: tx.merchant ?? "Unknown",
                        description: tx.rawDescription,
                        amount: tx.amount
                    )
                }

                let stream = await aiRepository.streamingCategorizeTransactions(txData)

                var index = 0
                do {
                    for try await categorization in stream {
                        guard index < transactions.count else { break }
                        let transaction = transactions[index]

                        if let category = CategoryEntity.from(string: categorization.category) {
                            transaction.category = category
                            transaction.isUserEdited = false
                            try context.save()
                            continuation.yield(())
                        }

                        index += 1
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func generateMonthlyInsights(for month: Date, context: ModelContext) async -> Result<MonthlyExpenseAnalysis, TransactionError> {
        // Fetch transactions for the month
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { tx in
                tx.date >= startOfMonth && tx.date <= endOfMonth
            }
        )

        do {
            let transactions = try context.fetch(descriptor)

            let txData = transactions.map { tx in
                (
                    merchant: tx.merchant ?? "Unknown",
                    amount: tx.amount,
                    category: tx.category.rawValue,
                    date: tx.date
                )
            }

            return await aiRepository.generateMonthlyAnalysis(
                transactions: txData,
                month: month
            )
        } catch {
            return .failure(.categorizationFailed("Failed to fetch transactions: \(error.localizedDescription)"))
        }
    }

    func checkModelAvailability() -> Bool {
        aiRepository.checkAvailability()
    }

    func prewarmModel() async -> Result<Void, TransactionError> {
        await aiRepository.prewarmModel()
    }
}

// Helper extension to map string to CategoryEntity
extension CategoryEntity {
    static func from(string: String) -> CategoryEntity? {
        let normalized = string.lowercased().trimmingCharacters(in: .whitespaces)
        return CategoryEntity.allCases.first { $0.rawValue.lowercased() == normalized }
    }
}
