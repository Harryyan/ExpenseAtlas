import Foundation

enum AIPrivacyMode: String, CaseIterable, Codable, Identifiable {
    case strictLocal
    case localPreferred
    case cloudAllowed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strictLocal: return "Strict Local"
        case .localPreferred: return "Local Preferred"
        case .cloudAllowed: return "Cloud Allowed"
        }
    }

    var allowsRemoteProvider: Bool {
        switch self {
        case .strictLocal, .localPreferred: return false
        case .cloudAllowed: return true
        }
    }
}

enum AIModelProviderKind: String, CaseIterable, Codable, Identifiable {
    case foundationModels
    case mlxLocal
    case remoteAPI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foundationModels: return "Apple Foundation Models"
        case .mlxLocal: return "MLX Local Model"
        case .remoteAPI: return "Remote Model API"
        }
    }

    var runsOnDevice: Bool {
        switch self {
        case .foundationModels, .mlxLocal: return true
        case .remoteAPI: return false
        }
    }
}

enum AIProviderAvailability: Equatable {
    case available
    case unavailable(reason: String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var unavailableReason: String? {
        if case .unavailable(let reason) = self {
            return reason
        }
        return nil
    }
}

struct AIProviderState: Equatable {
    let provider: AIModelProviderKind
    let availability: AIProviderAvailability
}

struct AIModelRoute: Identifiable, Equatable {
    let provider: AIModelProviderKind
    let availability: AIProviderAvailability
    let requiresExplicitConsent: Bool
    let priority: Int

    var id: AIModelProviderKind { provider }
    var isAvailable: Bool { availability.isAvailable }
}

struct AIModelRouter: Equatable {
    var privacyMode: AIPrivacyMode

    init(privacyMode: AIPrivacyMode = .strictLocal) {
        self.privacyMode = privacyMode
    }

    func orderedRoutes(providerStates: [AIProviderState]) -> [AIModelRoute] {
        providerStates
            .filter { privacyMode.allowsRemoteProvider || $0.provider.runsOnDevice }
            .map { state in
                AIModelRoute(
                    provider: state.provider,
                    availability: state.availability,
                    requiresExplicitConsent: !state.provider.runsOnDevice,
                    priority: priority(for: state.provider)
                )
            }
            .sorted { $0.priority < $1.priority }
    }

    func selectedRoute(providerStates: [AIProviderState]) -> AIModelRoute? {
        orderedRoutes(providerStates: providerStates).first { $0.isAvailable }
    }

    private func priority(for provider: AIModelProviderKind) -> Int {
        switch provider {
        case .foundationModels: return 0
        case .mlxLocal: return 1
        case .remoteAPI: return 2
        }
    }
}
