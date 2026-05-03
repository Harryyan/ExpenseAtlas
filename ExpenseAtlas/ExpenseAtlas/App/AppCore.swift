import Foundation
import SwiftData

final class AppCore {
    let statementProcessor: StatementProcessing
    let modelAvailability: ModelAvailabilityService
    let modelRouter: AIModelRouter
    let aiRepository: AIRepositoryProtocol

    init(statementProcessor: StatementProcessing,
         modelAvailability: ModelAvailabilityService,
         modelRouter: AIModelRouter,
         aiRepository: AIRepositoryProtocol) {
        self.statementProcessor = statementProcessor
        self.modelAvailability = modelAvailability
        self.modelRouter = modelRouter
        self.aiRepository = aiRepository
    }

    static func live() -> AppCore {
        let modelAvailability = ModelAvailabilityService.shared
        let modelRouter = AIModelRouter(privacyMode: .strictLocal)
        let foundationService = FoundationModelsService()
        let aiRepo = AIRepository(
            foundationService: foundationService,
            modelAvailability: modelAvailability,
            modelRouter: modelRouter
        )

        // Use AI-powered PDF processor for real transaction extraction
        let pdfProcessor = PDFStatementProcessor(aiRepository: aiRepo)

        return AppCore(
            statementProcessor: pdfProcessor,
            modelAvailability: modelAvailability,
            modelRouter: modelRouter,
            aiRepository: aiRepo
        )
    }
}
