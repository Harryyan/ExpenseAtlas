import Foundation

final class DetailFeatureFactory {
    private let core: AppCore
    
    init(core: AppCore) { self.core = core }

    @MainActor
    func makeDetailViewModel() -> DetailViewModel {
        let folderRepo: FolderRepository = FolderRepositoryImpl()
        let statementRepo: StatementRepository = StatementRepositoryImpl()

        let statementUC: StatementUseCase = StatementUseCaseImpl(
            statementRepo: statementRepo,
            folderRepo: folderRepo,
            processor: core.statementProcessor
        )

        return DetailViewModel(statementUC: statementUC)
    }
}
