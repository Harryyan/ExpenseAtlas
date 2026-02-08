//
//  AIRepository.swift
//  ExpenseAtlas
//
//  Created by Claude on 08/02/2026.
//

import Foundation

final class AIRepository: AIRepositoryProtocol {
    private let foundationService: FoundationModelsServiceProtocol
    private let modelAvailability: ModelAvailabilityService

    init(foundationService: FoundationModelsServiceProtocol, modelAvailability: ModelAvailabilityService) {
        self.foundationService = foundationService
        self.modelAvailability = modelAvailability
    }

    func categorizeTransaction(merchant: String, description: String, amount: Decimal) async -> Result<TransactionCategorization, TransactionError> {
        guard modelAvailability.isAvailable else {
            let reason = modelAvailability.getUnavailabilityReason() ?? "Model unavailable"
            return .failure(.modelUnavailable(reason: reason))
        }

        do {
            let result = try await foundationService.categorizeTransaction(
                merchant: merchant,
                description: description,
                amount: amount
            )
            return .success(result)
        } catch let error as FoundationModelsError {
            return .failure(mapError(error))
        } catch {
            return .failure(.categorizationFailed(error.localizedDescription))
        }
    }

    func streamingCategorizeTransactions(_ transactions: [(merchant: String, description: String, amount: Decimal)]) async -> AsyncThrowingStream<TransactionCategorization, Error> {
        foundationService.streamingCategorizeTransactions(transactions)
    }

    func generateMonthlyAnalysis(transactions: [(merchant: String, amount: Decimal, category: String, date: Date)], month: Date) async -> Result<MonthlyExpenseAnalysis, TransactionError> {
        guard modelAvailability.isAvailable else {
            let reason = modelAvailability.getUnavailabilityReason() ?? "Model unavailable"
            return .failure(.modelUnavailable(reason: reason))
        }

        do {
            let result = try await foundationService.generateMonthlyAnalysis(
                transactions: transactions,
                month: month
            )
            return .success(result)
        } catch let error as FoundationModelsError {
            return .failure(mapError(error))
        } catch {
            return .failure(.categorizationFailed(error.localizedDescription))
        }
    }

    func extractTransactions(from text: String) async -> Result<[ExtractedTransaction], TransactionError> {
        guard modelAvailability.isAvailable else {
            let reason = modelAvailability.getUnavailabilityReason() ?? "Model unavailable"
            return .failure(.modelUnavailable(reason: reason))
        }

        do {
            let result = try await foundationService.extractTransactions(from: text)
            return .success(result.transactions)
        } catch let error as FoundationModelsError {
            return .failure(mapError(error))
        } catch {
            return .failure(.categorizationFailed(error.localizedDescription))
        }
    }

    func checkAvailability() -> Bool {
        modelAvailability.isAvailable
    }

    func prewarmModel() async -> Result<Void, TransactionError> {
        guard modelAvailability.isAvailable else {
            let reason = modelAvailability.getUnavailabilityReason() ?? "Model unavailable"
            return .failure(.modelUnavailable(reason: reason))
        }

        do {
            try await foundationService.prewarmSession()
            return .success(())
        } catch {
            return .failure(.sessionNotInitialized)
        }
    }

    func resetSession() async -> Result<Void, TransactionError> {
        foundationService.resetSession()
        return .success(())
    }

    private func mapError(_ error: FoundationModelsError) -> TransactionError {
        switch error {
        case .contextWindowExceeded:
            return .contextWindowExceeded
        case .sessionTimeout:
            return .rateLimited
        case .generationFailed(let message):
            return .categorizationFailed(message)
        case .sessionNotInitialized:
            return .sessionNotInitialized
        case .invalidContent:
            return .invalidTransaction
        }
    }
}
