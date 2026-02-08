import Foundation
import SwiftData

final class AppCore {
    let statementProcessor: StatementProcessing
    let modelAvailability: ModelAvailabilityService
    let aiRepository: AIRepositoryProtocol

    init(statementProcessor: StatementProcessing,
         modelAvailability: ModelAvailabilityService,
         aiRepository: AIRepositoryProtocol) {
        self.statementProcessor = statementProcessor
        self.modelAvailability = modelAvailability
        self.aiRepository = aiRepository
    }

    static func live() -> AppCore {
        let modelAvailability = ModelAvailabilityService.shared
        let foundationService = FoundationModelsService()
        let aiRepo = AIRepository(
            foundationService: foundationService,
            modelAvailability: modelAvailability
        )

        // Use AI-powered PDF processor for real transaction extraction
        let pdfProcessor = PDFStatementProcessor(aiRepository: aiRepo)

        return AppCore(
            statementProcessor: pdfProcessor,
            modelAvailability: modelAvailability,
            aiRepository: aiRepo
        )
    }
}
