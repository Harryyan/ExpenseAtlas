import Foundation

final class AtlasFeatureFactory {
    private let core: AppCore
    
    init(core: AppCore) { self.core = core }
    
    @MainActor
    func makeAtlasViewModel() -> AtlasViewModel {
        AtlasViewModel()
    }
}
