//
//  GeneratorError.swift
//  Cooked
//
//  Created by David James on 06/05/2026.
//

import FoundationModels

enum GeneratorError: Error {
    case availability(SystemLanguageModel.Availability.UnavailableReason)
    case modelRefusal(String)
    case cancelled
    var requiresAlert: Bool {
        switch self {
        case .availability, .modelRefusal: true
        case .cancelled: false
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
            print("Rate Limited:", context)
        case .exceededContextWindowSize(let context):
            print("Context Window:", context)
        case .assetsUnavailable(let context):
            print("Assets Unavailable:", context)
        case .guardrailViolation(let context):
            print("Guardrail Violation:", context)
            FeedbackLogger.log(session: self, sentiment: .negative, issues: [.init(category: .triggeredGuardrailUnexpectedly, explanation: "Lists of food ingredients and varieties, individually one or two words are triggering guardrail violations based on single words without any context like 'black' or 'blonde' or 'goose' or 'turkey' e.g. in reference to food descriptions.")], desiredOutput: .response(.init(assetIDs: [], segments: [.text(.init(content: ""))])))
            print(FeedbackLogger.feedbackFileURL)
        case .unsupportedGuide(let context):
            print("Unsupported Guide:", context)
        case .unsupportedLanguageOrLocale(let context):
            print("Unsupported Language or Locale:", context)
        case .decodingFailure(let context):
            print("Decoding Failure:", context)
        case .concurrentRequests(let context):
            print("Concurrent Request Error:", context)
        case .refusal(let refusal, let context):
            print("Refusal:", refusal)
            print(context)
        @unknown default:
            fatalError()
        }
        print("------ TRANSCRIPT ------")
        print(transcript)
        print("------------------------")
    }
}
