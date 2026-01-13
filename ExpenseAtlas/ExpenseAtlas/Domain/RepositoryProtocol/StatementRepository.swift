import Foundation
import SwiftData

protocol StatementRepository {
    func importDocs(_ urls: [URL], into folder: Folder?, context: ModelContext) throws
    func deleteDoc(_ doc: StatementDoc, context: ModelContext) throws
    
    func updateDocStatus(_ doc: StatementDoc, status: DocStatus, error: String?, context: ModelContext) throws
    func setLastAnalyzed(_ doc: StatementDoc, date: Date, context: ModelContext) throws
}
