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

/// Observable view model responsible for generating anything from the local SLM
@MainActor
class Generator {
    
    var error: Error?
    
    let session: LanguageModelSession
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
    
    init(instructions: Instructions, tools: [any Tool], modelContext: ModelContext) throws {
        let instructions = Instructions {
            // "Follow these instructions"
            instructions
        }
        let slm = SystemLanguageModel.default
        if case .unavailable(let reason) = slm.availability {
            throw GeneratorError.availability(reason)
        }
        self.session = .init(model: slm, tools: tools, instructions: instructions)
        self.modelContext = modelContext
        
        print("Region:", Self.regionName)
    }

}
