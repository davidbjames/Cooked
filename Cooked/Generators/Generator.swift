//
//  Generator.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import Foundation
import FoundationModels
import SwiftData

enum GeneratorError: Error {
    case availability(SystemLanguageModel.Availability.UnavailableReason)
    var reason: SystemLanguageModel.Availability.UnavailableReason {
        switch self {
        case .availability(let reason): reason
        }
    }
}
extension SystemLanguageModel.Availability {
    var isAvailable: Bool {
        switch self {
        case .available: true
        case .unavailable: false
        }
    }
    var isSupported: Bool {
        switch self {
        case .unavailable(.deviceNotEligible): false
        default: true
        }
    }
}

extension LanguageModelSession {
    func handleGenerationError(_ error: GenerationError) {
        print("GENERATION ERROR", error)
        switch error {
        case .rateLimited(let context):
            print(context)
        case .exceededContextWindowSize(let context):
            print(context)
        case .assetsUnavailable(let context):
            print(context)
        case .guardrailViolation(let context):
            print(context)
            FeedbackLogger.log(session: self, sentiment: .negative, issues: [.init(category: .triggeredGuardrailUnexpectedly, explanation: "Lists of food ingredients and varieties, individually one or two words are triggering guardrail violations based on single words without any context like 'black' or 'blonde' or 'goose' or 'turkey' e.g. in reference to food descriptions.")], desiredOutput: .response(.init(assetIDs: [], segments: [.text(.init(content: ""))])))
            print(FeedbackLogger.feedbackFileURL)
        case .unsupportedGuide(let context):
            print(context)
        case .unsupportedLanguageOrLocale(let context):
            print(context)
        case .decodingFailure(let context):
            print(context)
        case .concurrentRequests(let context):
            print(context)
        case .refusal(let refusal, let context):
            print(refusal)
            print(context)
        @unknown default:
            fatalError()
        }
        print("------ TRANSCRIPT ------")
        print(transcript)
        print("------------------------")
    }
}

/// Observable view model responsible for generating anything from the local SLM
@MainActor
class Generator {
    
    let modelContext: ModelContext
    
    static var regionName: String = {
        let regionName: String
        if let regionCode = Locale.current.region?.identifier, let name = Locale(identifier: "en_US").localizedString(forRegionCode: regionCode) {
            regionName = name
        } else {
            regionName = "United States"
        }
        return regionName
    }()
    
    final class CancellationToken {
        var isCancelled = false
    }

    init(modelContext: ModelContext) throws {
        let slm = SystemLanguageModel.default
        // throw GeneratorError.availability(.deviceNotEligible)
        if case .unavailable(let reason) = slm.availability {
            throw GeneratorError.availability(reason)
        }
        self.modelContext = modelContext
        
        print("Region:", Self.regionName)
    }

}
