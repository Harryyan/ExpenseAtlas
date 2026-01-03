//
//  Item.swift
//  ExpenseAtlas
//
//  Created by Harry Yan on 01/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    // 一个 folder 下有多个 statement 文件
    @Relationship(deleteRule: .cascade) var docs: [StatementDoc]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.docs = []
    }
}

@Model
final class StatementDoc {
    // MARK: - Identity
    @Attribute(.unique)
    var id: UUID
    
    // MARK: - Basic Info
    var title: String                  // 显示在列表中的名字
    var originalFileName: String       // 原始文件名
    var fileType: FileType             // pdf / csv / ofx ...
    var importedAt: Date
    
    // MARK: - File Storage
    var localFilePath: String          // App container 内路径（relative）
    var fileSize: Int64
    
    // MARK: - Analysis State
    var status: Status                 // idle / processing / done / failed
    var lastAnalyzedAt: Date?
    var errorMessage: String?
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]
    
    @Relationship
    var folder: Folder?
    
    // MARK: - Init
    init(
        title: String,
        originalFileName: String,
        fileType: FileType,
        localFilePath: String,
        fileSize: Int64,
        folder: Folder?
    ) {
        self.id = UUID()
        self.title = title
        self.originalFileName = originalFileName
        self.fileType = fileType
        self.localFilePath = localFilePath
        self.fileSize = fileSize
        self.folder = folder
        
        self.importedAt = .now
        self.status = .idle
        self.transactions = []
    }
}

enum FileType: String, Codable, CaseIterable {
    case pdf
    case csv
    case ofx
    case qif
    case unknown
}

enum Status: String, Codable, CaseIterable {
    case idle        // 已导入，未分析
    case processing  // 正在解析
    case done        // 已生成花销地图
    case failed      // 解析失败
}

@Model
final class Transaction {
    
    // MARK: - Identity
    @Attribute(.unique)
    var id: UUID
    
    // MARK: - Core Fields
    var date: Date
    var amount: Decimal              // 一定用 Decimal，不要 Double
    var currency: String             // "USD", "CNY", "EUR"
    var direction: Direction         // debit / credit
    
    // MARK: - Description
    var rawDescription: String       // statement 原始描述
    var merchant: String?            // 归一化后的商户名（可为空）
    
    // MARK: - Categorization
    var category: Category
    var isUserEdited: Bool           // 用户是否手动改过分类
    
    // MARK: - Optional Financial Info
    var balance: Decimal?            // 有些 statement 会提供
    var reference: String?           // 交易号 / reference id
    
    // MARK: - Metadata
    var createdAt: Date
    var sourceLine: String?          // 原始行文本（调试/回溯用）
    
    // MARK: - Relationships
    var document: StatementDoc?
    
    // MARK: - Init
    init(
        date: Date,
        amount: Decimal,
        currency: String,
        direction: Direction,
        rawDescription: String,
        merchant: String? = nil,
        category: Category = .unknown,
        isUserEdited: Bool = false,
        balance: Decimal? = nil,
        reference: String? = nil,
        sourceLine: String? = nil,
        document: StatementDoc?
    ) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.currency = currency
        self.direction = direction
        self.rawDescription = rawDescription
        self.merchant = merchant
        self.category = category
        self.isUserEdited = isUserEdited
        self.balance = balance
        self.reference = reference
        self.sourceLine = sourceLine
        self.document = document
        self.createdAt = .now
    }
}

enum Direction: String, Codable, CaseIterable {
    case debit     // 支出
    case credit    // 收入
}

enum Category: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case groceries
    case dining
    case transport
    case shopping
    case housing
    case utilities
    case subscription
    case healthcare
    case entertainment
    case travel
    case transfer
    case income
    case fee
    case tax
    case unknown
    
    var displayName: String {
        switch self {
        case .groceries: return "Groceries"
        case .dining: return "Dining"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .housing: return "Housing"
        case .utilities: return "Utilities"
        case .subscription: return "Subscription"
        case .healthcare: return "Healthcare"
        case .entertainment: return "Entertainment"
        case .travel: return "Travel"
        case .transfer: return "Transfer"
        case .income: return "Income"
        case .fee: return "Fee"
        case .tax: return "Tax"
        case .unknown: return "Uncategorized"
        }
    }
    
    var systemImage: String {
        switch self {
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .transport: return "car"
        case .shopping: return "bag"
        case .housing: return "house"
        case .utilities: return "bolt"
        case .subscription: return "repeat"
        case .healthcare: return "heart"
        case .entertainment: return "tv"
        case .travel: return "airplane"
        case .transfer: return "arrow.left.arrow.right"
        case .income: return "arrow.down.circle"
        case .fee: return "exclamationmark.triangle"
        case .tax: return "percent"
        case .unknown: return "questionmark.circle"
        }
    }
}

extension StatementDoc {
    var subtitle: String {
        switch status {
        case .idle:
            return "Not analyzed"
        case .processing:
            return "Analyzing…"
        case .done:
            return "\(transactions.count) transactions"
        case .failed:
            return errorMessage ?? "Failed"
        }
    }
}
