import Foundation

final class LibraryFeatureFactory {
    private let core: AppCore
    
    init(core: AppCore) { self.core = core }
    
    @MainActor
    func makeRootViewModel() -> RootViewModel {
        return RootViewModel(folderUseCase: FolderUseCaseImpl(repo: FolderRepositoryImpl()),
                             statementUseCase: StatementUseCaseImpl(statementRepo:  StatementRepositoryImpl(),
                                                                    folderRepo: FolderRepositoryImpl(),
                                                                    processor: DemoStatementProcessor()))
    }
}
