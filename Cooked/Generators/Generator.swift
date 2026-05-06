//
//  Generator.swift
//  Cooked
//
//  Created by David James on 15/04/2026.
//

import Foundation
import FoundationModels
import SwiftData

/// Observable view model responsible for generating anything from the local SLM.
/// This base class should remain general enough for any type of generation.
@MainActor
class Generator {
    
    let modelContext: ModelContext
    
    /// Holds pre-run configuration set up by factory methods before `generate()` is called.
    /// Add new per-run state here rather than as ad-hoc properties on subclasses.
    struct Configuration {
        var tools: [any Tool] = []
        var token: GenerationToken = .init()
        var debug: Bool {
            #if DEBUG
            true
            #else
            false
            #endif
        }
    }
    
    var configuration = Configuration()
    
    var token: GenerationToken {
        get {
            configuration.token
        }
        set {
            configuration.token = newValue
        }
    }
    var debug: Bool {
        configuration.debug
    }
    
    static var regionName: String = {
        let regionName: String
        if let regionCode = Locale.current.region?.identifier, let name = Locale(identifier: "en_US").localizedString(forRegionCode: regionCode) {
            regionName = name
        } else {
            regionName = "United States"
        }
        return regionName
    }()
    
    final class GenerationToken {
        var isCancelled = false
    }

    init(modelContext: ModelContext, token: GenerationToken = .init()) throws {
        let slm = SystemLanguageModel.default
        // throw GeneratorError.availability(.deviceNotEligible)
        if case .unavailable(let reason) = slm.availability {
            throw GeneratorError.availability(reason)
        }
        self.modelContext = modelContext
        self.configuration.token = token
        
        print("Region:", Self.regionName)
    }
    
    func generate() async throws(GeneratorError) {
        // Base implementation — subclasses override
    }
    
    func makeDegenerateDetector() -> any DegenerateDetector {
        NonDegenerateDetector()
    }
}

