import SwiftData

protocol FolderRepository {
    func create(name: String, context: ModelContext) throws
    func delete(_ folder: Folder, context: ModelContext) throws
    func rename(_ folder: Folder, newName: String, context: ModelContext) throws
    func touch(_ folder: Folder, context: ModelContext) throws
}
