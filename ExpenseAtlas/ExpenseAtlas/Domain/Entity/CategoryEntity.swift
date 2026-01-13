import Foundation
import SwiftData

enum CategoryEntity: String, Codable, CaseIterable, Identifiable {
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
