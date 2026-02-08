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
        You are parsing an ANZ Bank New Zealand statement. Extract all transactions accurately.

        ⚠️ CRITICAL: This statement has a TABULAR FORMAT with these EXACT columns:

        | Date | Type | Details | Deposits | Withdrawals | Balance |

        Example rows from this exact format:

        07 Feb 2026 | Transfer | To: 06-0229-0822520-00     |        | $1.00    | $2,692.47
                    |          | Debit Transfer 114139      |        |          |
        07 Feb 2026 | Payment  | Yan                        |        | $20.00   | $2,693.47
        06 Feb 2026 | Transfer | From: 06-0229-0822520-00   | $17.44 |          | $3,018.40
                    |          | Credit Transfer 215845     |        |          |

        🚨 EXTRACTION RULES - READ EVERY WORD:

        1️⃣ DATE EXTRACTION:
           - Located in FIRST column labeled "Date"
           - Format: "07 Feb 2026", "06 Feb 2026", "30 Jan 2026"
           - ⚠️ NEVER extract the day number (07, 06, 30) as an amount!
           - Extract the FULL date string: "07 Feb 2026"

        2️⃣ AMOUNT EXTRACTION - THIS IS WHERE MISTAKES HAPPEN:
           ⚠️ The "Deposits" and "Withdrawals" columns are SEPARATE from the Date column!

           Step-by-step process:
           a) Identify if the row has money in the "Deposits" column (4th column)
              - If YES: Extract that amount → type is "credit"
           b) Identify if the row has money in the "Withdrawals" column (5th column)
              - If YES: Extract that amount → type is "debit"
           c) ⚠️ IGNORE the "Balance" column (6th column) - it's the running total, NOT the transaction amount
           d) ⚠️ IGNORE any numbers in the "Date" column (1st column) - those are dates, NOT amounts!

           Example corrections:
           ❌ WRONG: See "07 Feb 2026" → extract amount "7.00" (this is a date, not an amount!)
           ✅ CORRECT: See "07 Feb 2026" → read across to "Withdrawals" column → extract "$1.00"

           ❌ WRONG: See "02 Feb 2026" → extract amount "2.00" (this is a date!)
           ✅ CORRECT: See "02 Feb 2026" in Date column, then read "Withdrawals" column for actual amount

           Real example from statement:
           Row: "26 Jan 2026 | Transfer | To: 06-0229-0822520-00 Debit Transfer 123638 | | $2.00 | $3,184.30"
           - Date column: "26 Jan 2026" (don't extract "26" as amount!)
           - Deposits column: empty
           - Withdrawals column: "$2.00" ← THIS is the amount to extract
           - Balance column: "$3,184.30" (ignore this)
           → Extract: date="26 Jan 2026", amount="2.00", type="debit"

        3️⃣ DESCRIPTION EXTRACTION:
           - Located in "Details" column (3rd column)
           - Often spans multiple lines for transfers
           - Include ALL details:
             * For transfers: "Transfer From: 06-0229-0822520-00 Credit Transfer 215845"
             * For payments: "Nid Renters Limited Lan Rent 3/11 Hatfield Alb"
             * For salary: "Mega Privacy Nz Li Payroll"

        4️⃣ TRANSACTION TYPE:
           - "debit" if amount is in the "Withdrawals" column (money leaving account)
           - "credit" if amount is in the "Deposits" column (money entering account)

        5️⃣ CURRENCY:
           - This is an ANZ New Zealand statement
           - Currency is always "NZD" (New Zealand Dollars)
           - Amounts shown with $ symbol in statement

        📋 EXAMPLE EXTRACTIONS FROM THIS EXACT STATEMENT:

        Row 1: "07 Feb 2026 | Transfer | To: 06-0229-0822520-00 Debit Transfer 114139 | | $1.00 | $2,692.47"
        Extract:
        {
          "date": "07 Feb 2026",
          "description": "Transfer To: 06-0229-0822520-00 Debit Transfer 114139",
          "amount": "1.00",
          "currency": "NZD",
          "type": "debit"
        }

        Row 2: "06 Feb 2026 | Transfer | From: 06-0229-0822520-00 Credit Transfer 215845 | $17.44 | | $3,018.40"
        Extract:
        {
          "date": "06 Feb 2026",
          "description": "Transfer From: 06-0229-0822520-00 Credit Transfer 215845",
          "amount": "17.44",
          "currency": "NZD",
          "type": "credit"
        }

        Row 3: "04 Feb 2026 | Payment | Nid Renters Limited Lan Rent 3/11 Hatfield Alb | | $880.00 | $3,159.96"
        Extract:
        {
          "date": "04 Feb 2026",
          "description": "Nid Renters Limited Lan Rent 3/11 Hatfield Alb",
          "amount": "880.00",
          "currency": "NZD",
          "type": "debit"
        }

        🔍 FINAL CHECK BEFORE EXTRACTION:
        - Did you extract amounts from "Deposits" or "Withdrawals" columns? ✓
        - Did you avoid extracting dates as amounts? ✓
        - Did you preserve decimal places (e.g., "17.44" not "17")? ✓
        - Did you include full descriptions including transfer details? ✓

        Now extract ALL transactions from this statement:

        \(text)
        """
    }
}
