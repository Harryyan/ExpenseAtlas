import Foundation

final class LibraryFeatureFactory {
    private let core: AppCore
    
    init(core: AppCore) { self.core = core }
    
    @MainActor
    func makeRootViewModel() -> RootViewModel {
        RootViewModel(folderUseCase: FolderUseCaseImpl(repo: FolderRepositoryImpl()),
                      statementUseCase: StatementUseCaseImpl(statementRepo:  StatementRepositoryImpl(),
                                                             folderRepo: FolderRepositoryImpl(),
                                                             processor: core.statementProcessor))
    }

    @MainActor
    func makeDocumentListViewModel(folder: Folder?) -> DocumentListViewModel {
        DocumentListViewModel(
            folder: folder,
            statementUseCase: StatementUseCaseImpl(
                statementRepo: StatementRepositoryImpl(),
                folderRepo: FolderRepositoryImpl(),
                processor: core.statementProcessor
            )
        )
    }
}
