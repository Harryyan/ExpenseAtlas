import Foundation
import SwiftData

protocol FolderUseCase {
    func create(name: String, context: ModelContext) throws
    func delete(_ folder: Folder, context: ModelContext) throws
    func rename(_ folder: Folder, newName: String, context: ModelContext) throws
    func touch(_ folder: Folder, context: ModelContext) throws
}

struct FolderUseCaseImpl: FolderUseCase {
    let repo: FolderRepository
    
    func create(name: String, context: ModelContext) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try repo.create(name: trimmed, context: context)
    }
    
    func delete(_ folder: Folder, context: ModelContext) throws {
        try repo.delete(folder, context: context)
    }
    
    func rename(_ folder: Folder, newName: String, context: ModelContext) throws {
        try repo.rename(folder, newName: newName, context: context)
    }
    
    func touch(_ folder: Folder, context: ModelContext) throws {
        try repo.touch(folder, context: context)
    }
}
