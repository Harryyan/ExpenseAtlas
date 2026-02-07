import Observation
import SwiftData

@MainActor
@Observable
final class DetailViewModel {
    private let statementUC: StatementUseCase

    var showError: Bool = false
    var errorMessage: String?

    init(statementUC: StatementUseCase) {
        self.statementUC = statementUC
    }

    func generate(doc: StatementDoc, context: ModelContext) {
        Task {
            do {
                try await statementUC.generateInsights(for: doc, context: context)
            } catch {
                errorMessage = String(describing: error)
                showError = true
            }
        }
    }
}
