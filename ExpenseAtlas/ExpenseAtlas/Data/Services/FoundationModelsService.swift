//
//  FoundationModelsService.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation
import FoundationModels

enum FoundationModelsError: Error {
    case contextWindowExceeded
    case sessionTimeout
    case generationFailed(String)
    case sessionNotInitialized
    case invalidContent
}

protocol FoundationModelsServiceProtocol {
    func categorizeTransaction(merchant: String, description: String, amount: Decimal) async throws -> TransactionCategorization
    func streamingCategorizeTransactions(_ transactions: [(merchant: String, description: String, amount: Decimal)]) -> AsyncThrowingStream<TransactionCategorization, Error>
    func generateMonthlyAnalysis(transactions: [(merchant: String, amount: Decimal, category: String, date: Date)], month: Date) async throws -> MonthlyExpenseAnalysis
    func extractTransactions(from text: String) async throws -> TransactionExtraction
    func prewarmSession() async throws
    func resetSession()
}

final class FoundationModelsService: FoundationModelsServiceProtocol {
    private var session: LanguageModelSession?
    private var isPrewarmed = false

    init() {
        initializeSession()
    }

    private func initializeSession() {
        let instructions = createSystemInstruction()
        session = LanguageModelSession(instructions: instructions)
    }

    func extractTransactions(from text: String) async throws -> TransactionExtraction {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }

        let prompt = buildTransactionExtractionPrompt(text: text)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: TransactionExtraction.self,
                options: GenerationOptions(temperature: 0.1)
            )
            return response.content
        } catch {
            throw FoundationModelsError.generationFailed(error.localizedDescription)
        }
    }

    func resetSession() {
        session = nil
        isPrewarmed = false
        initializeSession()
    }

    func prewarmSession() async throws {
        guard let session = session, !isPrewarmed else { return }

        print("Prewarming Foundation Models session for transaction categorization...")
        session.prewarm()
        isPrewarmed = true
        print("Foundation Models session prewarming completed")
    }

    func categorizeTransaction(merchant: String, description: String, amount: Decimal) async throws -> TransactionCategorization {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }

        let prompt = buildCategorizationPrompt(merchant: merchant, description: description, amount: amount)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: TransactionCategorization.self,
                options: GenerationOptions(temperature: 0.3)
            )
            return response.content
        } catch {
            throw FoundationModelsError.generationFailed(error.localizedDescription)
        }
    }

    func streamingCategorizeTransactions(_ transactions: [(merchant: String, description: String, amount: Decimal)]) -> AsyncThrowingStream<TransactionCategorization, Error> {
        guard let session = session else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: FoundationModelsError.sessionNotInitialized)
            }
        }

        let txCopy = transactions
        return AsyncThrowingStream { continuation in
            Task {
                for transaction in txCopy {
                    do {
                        let prompt = """
                        Categorize this bank transaction:

                        Merchant: \(transaction.merchant)
                        Description: \(transaction.description)
                        Amount: \(transaction.amount)

                        Available categories: groceries, dining, transport, shopping, housing, utilities, subscription, healthcare, entertainment, travel, transfer, income, fee, tax, unknown

                        Rules:
                        - Analyze merchant name and description
                        - Assign the most appropriate category
                        - Provide confidence score (0.0-1.0)
                        - Explain reasoning briefly
                        """

                        let response = try await session.respond(
                            to: prompt,
                            generating: TransactionCategorization.self,
                            options: GenerationOptions(temperature: 0.3)
                        )
                        continuation.yield(response.content)
                    } catch {
                        continuation.finish(throwing: FoundationModelsError.generationFailed(error.localizedDescription))
                        return
                    }
                }
                continuation.finish()
            }
        }
    }

    func generateMonthlyAnalysis(transactions: [(merchant: String, amount: Decimal, category: String, date: Date)], month: Date) async throws -> MonthlyExpenseAnalysis {
        guard let session = session else {
            throw FoundationModelsError.sessionNotInitialized
        }

        let prompt = buildMonthlyAnalysisPrompt(transactions: transactions, month: month)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: MonthlyExpenseAnalysis.self,
                options: GenerationOptions(temperature: 0.5)
            )
            return response.content
        } catch {
            throw FoundationModelsError.generationFailed(error.localizedDescription)
        }
    }

    private func createSystemInstruction() -> String {
        """
        You are a financial assistant specialized in categorizing bank transactions and analyzing spending patterns.

        SAFETY GUIDELINES:
        - Only analyze the provided transaction data
        - Generate professional, neutral analysis
        - Focus on factual financial insights
        - Maintain objectivity and accuracy

        CATEGORIZATION GUIDELINES:
        - Analyze merchant name and description carefully
        - Assign the most appropriate category
        - Provide confidence scores (0.0-1.0)
        - Explain reasoning briefly and clearly

        ANALYSIS GUIDELINES:
        - Identify spending patterns and trends
        - Provide actionable insights
        - Suggest realistic money-saving opportunities
        - Maintain a helpful, non-judgmental tone
        """
    }

    private func buildCategorizationPrompt(merchant: String, description: String, amount: Decimal) -> String {
        """
        Categorize this bank transaction:

        Merchant: \(merchant)
        Description: \(description)
        Amount: \(amount)

        Available categories: groceries, dining, transport, shopping, housing, utilities, subscription, healthcare, entertainment, travel, transfer, income, fee, tax, unknown

        Rules:
        - Analyze merchant name and description
        - Assign the most appropriate category
        - Provide confidence score (0.0-1.0)
        - Explain reasoning briefly
        """
    }

    private func buildMonthlyAnalysisPrompt(transactions: [(merchant: String, amount: Decimal, category: String, date: Date)], month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthString = formatter.string(from: month)

        var transactionList = "Transactions for \(monthString):\n"
        for (index, tx) in transactions.prefix(50).enumerated() {
            transactionList += "\n\(index + 1). \(tx.merchant): $\(tx.amount) (\(tx.category))"
        }

        return """
        Analyze these monthly expenses and provide insights:

        \(transactionList)

        Provide:
        1. Total spending summary
        2. Top 5 spending categories
        3. Top 5 merchants
        4. Spending patterns and insights (3-5 bullet points)
        5. Money-saving recommendations (2-3 suggestions)
        """
    }

    private func buildTransactionExtractionPrompt(text: String) -> String {
        """
        You are a financial document parser. Extract all bank transactions from this statement.

        SAFETY GUIDELINES:
        - Only extract factual transaction data
        - Do not infer or add information not present in the text
        - If a field is unclear, use empty string or "unknown"

        EXTRACTION RULES:
        - Find all transaction rows (date, description, amount)
        - Dates may be in various formats (MM/DD/YYYY, DD/MM/YYYY, etc.)
        - Amounts may have commas, decimals, or negative signs
        - Identify debit vs credit transactions (debits often have minus signs or in separate columns)
        - Extract currency if mentioned, otherwise use USD
        - Include running balance if available

        Bank Statement Text:
        \(text)

        Extract ALL transactions found in the statement in chronological order.
        """
    }
}
