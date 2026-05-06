//
//  Playground.swift
//  Cooked
//
//  Created by David James on 09/04/2026.
//

import FoundationModels
import Playgrounds

#Playground {
    let model = SystemLanguageModel.default
    // should always check if the model is available
    // and fail gracefully, including prompting the user
    // to resolve the situation.
    switch model.availability {
    case .available:
        print("Foundation Models is available and ready to go!")
        
    case .unavailable(.deviceNotEligible):
        // AI not supported on this device
        print("The model is not available on this device.")
        
    case .unavailable(.appleIntelligenceNotEnabled):
        // AI is turned off
        print("Apple Intelligence is not enabled in Settings.")
        
    case .unavailable(.modelNotReady):
        // Try downloading again
        print("The model is not ready yet. Please try again later.")
        
    case .unavailable:
        print("The model is unavailable for an unknown reason.")
    }
//    let instructions = "A food type is a combination of a general type and a specific type which is usually an adjective (e.g. 'basmati rice' is the specialized and general type in one phrase)."
    let session = LanguageModelSession()
    let prompt = "Create a list of 5 food types"
    do {
        _ = try await session.respond(to: prompt, generating: [GeneratedIngredient].self)
    } catch {
        print(error) 
    }

}
