import Foundation
import SwiftData

@Model
final class Folder {
    @Attribute(.unique)
    var id: UUID                // TODO: Cloudkit sync may have issue, need to verify
   
    @Relationship(deleteRule: .cascade)
    var docs: [StatementDoc]
    
    var name: String
    var createdAt: Date
    var updateAt: Date
    
    init(name: String) {
        id = UUID()
        self.name = name
        
        let now = Date()
        createdAt = now
        updateAt = now
        
        docs = []
    }
}
