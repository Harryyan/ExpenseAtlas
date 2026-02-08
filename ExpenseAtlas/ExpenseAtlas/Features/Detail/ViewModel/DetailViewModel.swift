import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DetailViewModel {
    private let statementUC: StatementUseCase
    private let categorizationUC: TransactionCategorizationUseCaseProtocol

    var showError: Bool = false
    var errorMessage: String?

    var isCategorizing: Bool = false
    var categorizationProgress: Double = 0
    var categorizationTask: Task<Void, Never>?

    var shouldSwitchToTransactions: Bool = false

    init(statementUC: StatementUseCase, categorizationUC: TransactionCategorizationUseCaseProtocol) {
        self.statementUC = statementUC
        self.categorizationUC = categorizationUC
    }

    func generate(doc: StatementDoc, context: ModelContext) {
        Task {
            do {
                try await statementUC.generateInsights(for: doc, context: context)
                shouldSwitchToTransactions = true
            } catch {
                errorMessage = String(describing: error)
                showError = true
            }
        }
    }

    func startCategorization(doc: StatementDoc, context: ModelContext) {
        categorizationTask?.cancel()
        isCategorizing = true
        categorizationProgress = 0

        categorizationTask = Task {
            let transactions = doc.transactions
            guard !transactions.isEmpty else {
                isCategorizing = false
                return
            }

            let total = Double(transactions.count)
            var completed: Double = 0

            do {
                let stream = await categorizationUC.batchCategorize(transactions, context: context)

                for try await _ in stream {
                    try Task.checkCancellation()
                    completed += 1
                    categorizationProgress = completed / total
                }

                isCategorizing = false
                categorizationProgress = 1.0
                shouldSwitchToTransactions = true
            } catch is CancellationError {
                isCategorizing = false
            } catch {
                errorMessage = "Categorization failed: \(error.localizedDescription)"
                showError = true
                isCategorizing = false
            }
        }
    }

    func cancelCategorization() {
        categorizationTask?.cancel()
        isCategorizing = false
        categorizationProgress = 0
    }

    var isModelAvailable: Bool {
        categorizationUC.checkModelAvailability()
    }
}
