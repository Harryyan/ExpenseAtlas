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
        You are a financial assistant specialized in extracting transactions from bank statements (any bank, any country, any layout), categorizing them, and analyzing spending patterns.

        SAFETY GUIDELINES:
        - Only analyze the provided transaction data
        - Generate professional, neutral analysis
        - Focus on factual financial insights
        - Maintain objectivity and accuracy

        EXTRACTION GUIDELINES:
        - Infer column structure from headers and row patterns; do not assume a fixed layout
        - Read amounts from the money columns (Debit/Credit, Withdrawals/Deposits, signed Amount), never from the running balance column
        - Handle multiple date formats, currencies, and languages (incl. CJK)
        - Preserve the original date string and full description text

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
        Extract every transaction from the bank statement below. The statement may be from any bank, any country, any layout — do not assume a fixed format. Read carefully and infer the column structure from headers and row patterns.

        UNDERSTANDING STATEMENT LAYOUTS

        Bank statements typically include these columns (names vary by bank/language):
        - Date column: e.g. "Date", "Trans Date", "Posted", "日期", "记账日"
        - Description column: e.g. "Description", "Details", "Type", "Particulars", "摘要", "交易类型"
        - Money column(s) — one of these patterns:
          • Two separate columns: "Debit"/"Credit", "Withdrawals"/"Deposits", "支出"/"存入"
          • One signed Amount column where negative means outflow
          • One column with "DR"/"CR" suffix
        - Balance column: the running account total — NOT a transaction amount, IGNORE it for extraction

        EXTRACTION RULES

        1. DATE
           - Located in the date column (usually leftmost)
           - Keep the original format observed (e.g. "07 Feb 2026", "2026-02-07", "07/02/2026", "Feb 07, 2026", "2026年02月07日")
           - Do NOT mistake a day-of-month number for an amount

        2. AMOUNT
           - Read from the actual money column(s), NEVER from the balance column
           - Two-column layout: pick whichever column has a value on that row
           - Signed-amount layout: a negative sign indicates a debit
           - Strip currency symbols and thousand separators: "$1,234.56" → "1234.56"
           - Preserve decimal places when present (e.g. "17.44", not "17")

        3. TYPE
           - "debit"  = money leaves the account (withdrawal, payment, transfer out, fee, purchase, ATM)
           - "credit" = money enters the account (deposit, salary, refund, transfer in, interest)
           - Decision rules:
             • Value in Withdrawal/Debit/Payment column → debit
             • Value in Deposit/Credit column → credit
             • Negative signed amount → debit; positive → credit
             • "DR" suffix → debit; "CR" suffix → credit

        4. DESCRIPTION
           - Concatenate all descriptive text for the row (transfers often span multiple lines)
           - Preserve merchant names, transfer references, account numbers
           - Trim leading/trailing whitespace

        5. CURRENCY
           - Detect from statement header, account info, or symbols within the document
           - Common indicators: NZD, AUD, USD, EUR, GBP, CAD, CNY, JPY, or symbols $ € £ ¥
           - Apply the same currency to all transactions if a single currency is used throughout
           - If genuinely ambiguous, return your best inference

        EXAMPLES — DIFFERENT LAYOUTS

        Layout A — separate Withdrawals/Deposits columns (e.g. ANZ NZ):
          "07 Feb 2026 | Transfer | To: 06-0229-0822520-00 Debit Transfer 114139 | | $1.00 | $2,692.47"
          → date: "07 Feb 2026", description: "Transfer To: 06-0229-0822520-00 Debit Transfer 114139", amount: "1.00", currency: "NZD", type: "debit"

          "06 Feb 2026 | Transfer | From: 06-0229-0822520-00 Credit Transfer 215845 | $17.44 | | $3,018.40"
          → date: "06 Feb 2026", description: "Transfer From: 06-0229-0822520-00 Credit Transfer 215845", amount: "17.44", currency: "NZD", type: "credit"

        Layout B — single signed Amount column (e.g. many US banks):
          "2026-01-15  AMAZON.COM ORDER  -49.99  3,205.10"
          → date: "2026-01-15", description: "AMAZON.COM ORDER", amount: "49.99", currency: "USD", type: "debit"

        Layout C — DR/CR suffix (e.g. some AU/UK banks):
          "15/01/2026  PAYROLL DEPOSIT  3,500.00 CR  5,210.00"
          → date: "15/01/2026", description: "PAYROLL DEPOSIT", amount: "3500.00", currency: "AUD", type: "credit"

        Layout D — Chinese bank (e.g. 招行/中行):
          "2026-01-15  工资入账  +8,500.00  12,500.00"
          → date: "2026-01-15", description: "工资入账", amount: "8500.00", currency: "CNY", type: "credit"

        FINAL CHECKS BEFORE EMITTING EACH ROW
        - Read amount from the money column, NOT the balance column
        - No date number extracted as an amount
        - Decimal places preserved (e.g. "17.44", not "17")
        - Full multi-line description preserved

        Now extract every transaction from the statement below:

        \(text)
        """
    }
}
