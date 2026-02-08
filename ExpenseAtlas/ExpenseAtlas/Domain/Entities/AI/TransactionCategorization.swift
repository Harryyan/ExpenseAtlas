//
//  TransactionCategorization.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation
import FoundationModels

@Generable
struct TransactionCategorization: Codable {
    @Guide(description: "The most appropriate expense category for this transaction")
    let category: String

    @Guide(description: "Confidence score from 0.0 to 1.0 indicating how certain the categorization is")
    let confidence: Double

    @Guide(description: "Brief explanation of why this category was chosen")
    let reasoning: String
}

@Generable
struct CategorySpending: Codable {
    @Guide(description: "The expense category name")
    let category: String

    @Guide(description: "Total amount spent in this category")
    let amount: Double

    @Guide(description: "Percentage of total spending")
    let percentage: Double
}

@Generable
struct MerchantSpending: Codable {
    @Guide(description: "The merchant name")
    let merchant: String

    @Guide(description: "Total amount spent at this merchant")
    let amount: Double

    @Guide(description: "Number of transactions")
    let transactionCount: Int
}

@Generable
struct MonthlyExpenseAnalysis: Codable {
    @Guide(description: "Total amount spent during the month")
    let totalSpending: Double

    @Guide(description: "Top 5 spending categories with amounts and percentages")
    let topCategories: [CategorySpending]

    @Guide(description: "Top 5 merchants by spending amount")
    let topMerchants: [MerchantSpending]

    @Guide(description: "3-5 insights about spending patterns and trends")
    let insights: [String]

    @Guide(description: "2-3 actionable money-saving recommendations")
    let recommendations: [String]
}
