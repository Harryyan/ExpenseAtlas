import Foundation
import SwiftData

final class AppCore {
    let statementProcessor: StatementProcessing
    
    init(statementProcessor: StatementProcessing) {
        self.statementProcessor = statementProcessor
    }
    
    static func live() -> AppCore {
        AppCore(statementProcessor: DemoStatementProcessor())
    }
}
