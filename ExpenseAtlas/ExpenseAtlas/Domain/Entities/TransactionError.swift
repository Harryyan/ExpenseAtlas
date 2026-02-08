//
//  TransactionError.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation

enum TransactionError: Error, Equatable {
    case modelUnavailable(reason: String)
    case categorizationFailed(String)
    case contextWindowExceeded
    case rateLimited
    case invalidTransaction
    case streamingFailed
    case sessionNotInitialized

    var userFriendlyMessage: String {
        switch self {
        case .modelUnavailable(let reason):
            return reason
        case .categorizationFailed(let message):
            return "Categorization failed: \(message)"
        case .contextWindowExceeded:
            return "Too many transactions to process at once. Please try with fewer transactions."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .invalidTransaction:
            return "Invalid transaction data. Please check the transaction details."
        case .streamingFailed:
            return "Streaming categorization failed. Please try again."
        case .sessionNotInitialized:
            return "AI model not initialized. Please restart the app."
        }
    }
}
