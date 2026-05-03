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
    private let modelRouter: AIModelRouter

    init(
        foundationService: FoundationModelsServiceProtocol,
        modelAvailability: ModelAvailabilityService,
        modelRouter: AIModelRouter = AIModelRouter()
    ) {
        self.foundationService = foundationService
        self.modelAvailability = modelAvailability
        self.modelRouter = modelRouter
    }

    func categorizeTransaction(merchant: String, description: String, amount: Decimal) async -> Result<TransactionCategorization, TransactionError> {
        if case .failure(let error) = resolveFoundationModelsRoute() {
            return .failure(error)
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
        if case .failure(let error) = resolveFoundationModelsRoute() {
            return .failure(error)
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
        if case .failure(let error) = resolveFoundationModelsRoute() {
            return .failure(error)
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
        if case .success = resolveFoundationModelsRoute() {
            return true
        }
        return false
    }

    func prewarmModel() async -> Result<Void, TransactionError> {
        if case .failure(let error) = resolveFoundationModelsRoute() {
            return .failure(error)
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

    private func resolveFoundationModelsRoute() -> Result<Void, TransactionError> {
        guard let route = modelRouter.selectedRoute(providerStates: providerStates()) else {
            return .failure(routeUnavailableError())
        }

        guard route.provider == .foundationModels else {
            return .failure(.modelUnavailable(reason: "\(route.provider.displayName) is selected, but its provider is not implemented yet."))
        }

        return .success(())
    }

    private func providerStates() -> [AIProviderState] {
        [
            AIProviderState(
                provider: .foundationModels,
                availability: foundationModelsAvailability()
            ),
            AIProviderState(
                provider: .mlxLocal,
                availability: .unavailable(reason: "MLX local model support has not been configured yet.")
            ),
            AIProviderState(
                provider: .remoteAPI,
                availability: .unavailable(reason: "Remote model access is disabled until the user explicitly enables cloud processing.")
            )
        ]
    }

    private func foundationModelsAvailability() -> AIProviderAvailability {
        if modelAvailability.isAvailable {
            return .available
        }

        let reason = modelAvailability.getUnavailabilityReason() ?? "Apple Foundation Models is unavailable."
        return .unavailable(reason: reason)
    }

    private func routeUnavailableError() -> TransactionError {
        let routes = modelRouter.orderedRoutes(providerStates: providerStates())
        let reasons = routes.compactMap { route -> String? in
            guard let reason = route.availability.unavailableReason else { return nil }
            return "\(route.provider.displayName): \(reason)"
        }

        let message = reasons.isEmpty ? "No AI model provider is available." : reasons.joined(separator: "\n")
        return .modelUnavailable(reason: message)
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
