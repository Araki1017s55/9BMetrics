//
//  IntentHandler.swift
//  Gyrometrics
//
//  Created by Francisco Gorina Vanrell on 4/4/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Intents

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension, INStartWorkoutIntentHandling
//, INPauseWorkoutIntentHandling, INResumeWorkoutIntentHandling, INCancelWorkoutIntentHandling, INEndWorkoutIntentHandling 
{
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - INStartWorkoutIntentHandling
    
    func resolveIsOpenEnded(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        let resolutionResult = INBooleanResolutionResult.success(with: true)
        completion(resolutionResult)
    }
    
    func resolveGoalValue(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INDoubleResolutionResult) -> Void) {
        let resolutionResult = INDoubleResolutionResult.success(with: 5000)
        completion(resolutionResult)
    }
    
    func resolveWorkoutGoalUnitType(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutGoalUnitTypeResolutionResult) -> Void) {
        let resolutionResut = INWorkoutGoalUnitTypeResolutionResult.success(with: .meter)
        completion(resolutionResut)
    }
    
    func resolveWorkoutLocationType(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutLocationTypeResolutionResult) -> Void) {
        let resolutionResult = INWorkoutLocationTypeResolutionResult.success(with: .outdoor)
        completion(resolutionResult)
    }
    
    func resolveWorkoutName(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        
        let spkStr = INSpeakableString(spokenPhrase: "NOE003 Paco")
        
        let resolutionResult = INSpeakableStringResolutionResult.success(with: spkStr)//.disambiguation(with: [spkStr])
        completion(resolutionResult)
    }
    
    func confirm(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        
        let response = INStartWorkoutIntentResponse(code: .ready, userActivity: nil)
        completion(response)
        
    }
    
    func handle(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        
        let intentResponse = INStartWorkoutIntentResponse.init(code: .continueInApp, userActivity: nil)
        completion(intentResponse)
        
    }
    
    
  }

