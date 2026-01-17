import Foundation
import SwiftData

struct FolderRepositoryImpl: FolderRepository {
    
    func create(name: String, context: ModelContext) throws {
        let folder = Folder(name: name)
        context.insert(folder)
        try context.save()
    }
    
    func delete(_ folder: Folder, context: ModelContext) throws {
        context.delete(folder)
        try context.save()
    }
    
    func rename(_ folder: Folder, newName: String, context: ModelContext) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return }
        
        folder.name = trimmed
        try context.save()
    }
    
    func touch(_ folder: Folder, context: ModelContext) throws {
        try context.save()
    }
}
