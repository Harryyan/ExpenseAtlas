import Foundation

struct AppEnvironment {
    let core: AppCore

    let library: LibraryFeatureFactory
    let detail: DetailFeatureFactory
    let atlas: AtlasFeatureFactory

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
