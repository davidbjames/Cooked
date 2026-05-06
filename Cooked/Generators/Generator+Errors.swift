//
//  GeneratorError.swift
//  Cooked
//
//  Created by David James on 06/05/2026.
//

import FoundationModels

enum GeneratorError: Error {
    case availability(SystemLanguageModel.Availability.UnavailableReason)
    case cancelled
    var reason: SystemLanguageModel.Availability.UnavailableReason {
        switch self {
        case .availability(let reason): reason
        case .cancelled: fatalError("No availability reason for .cancelled")
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
