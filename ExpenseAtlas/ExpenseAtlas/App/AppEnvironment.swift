import Foundation

@Observable
final class AppEnvironment {
    let core: AppCore

    let library: LibraryFeatureFactory
    let detail: DetailFeatureFactory
    let atlas: AtlasFeatureFactory
    
    init(core: AppCore, library: LibraryFeatureFactory,
         detail: DetailFeatureFactory,
         atlas: AtlasFeatureFactory) {
        self.core = core
        self.library = library
        self.detail = detail
        self.atlas = atlas
    }

    static func live() -> AppEnvironment {
        let core = AppCore.live()
        
        return AppEnvironment(
            core: core,
            library: LibraryFeatureFactory(core: core),
            detail: DetailFeatureFactory(core: core),
            atlas: AtlasFeatureFactory(core: core)
        )
    }
}
