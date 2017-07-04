//
//  File.swift
//  SmashTag
//
//  Created by Bill on 6/14/17.
//  Copyright © 2017 Google Inc. All rights reserved.
//


//

enum PlayerState {
    case active
    case notActive
}

enum PlayerGameState {
    case won
    case lost
    case none
}

struct SmashTagUser {
    
    // MARK: Properties
    
    let playerName : String
    var playerIdentifier : String
    
    var playerState : String
    var playerGameState : String
    var gamePlayerIdentifier : String  // person buying a drink if "won"
    var gamePlayerName : String  // person buying a drink if "won"
                                       // person you owe a drink if "lost"
                                       // need a reset to replay
    
    let pictURL : String?  // optional as this is not required
    
    //  game partner

    let imageURL : String? = nil
    
    // MARK: Initializers
    
    init(dictionary: [String:String]) {
        
        //  bm - this adds a blank after each filed - not needed?
        playerName = dictionary[Constants.PlayerFields.name] != nil ? dictionary[Constants.PlayerFields.name] as String! + " " : ""
                
        playerIdentifier = dictionary[Constants.PlayerFields.playerIdentifier] != nil ? dictionary[Constants.PlayerFields.playerIdentifier] as String! : ""

        playerState = dictionary[Constants.PlayerFields.playerState] != nil ? dictionary[Constants.PlayerFields.playerState] as String! : ""

        playerGameState = dictionary[Constants.PlayerFields.playerGameState] != nil ? dictionary[Constants.PlayerFields.playerGameState] as String! : ""
        
        gamePlayerIdentifier = dictionary[Constants.PlayerFields.gamePlayerIdentifier] != nil ? dictionary[Constants.PlayerFields.gamePlayerIdentifier] as String! : ""
        
        gamePlayerName = dictionary[Constants.PlayerFields.gamePlayerName] != nil ? dictionary[Constants.PlayerFields.gamePlayerName] as String! : ""
        
        pictURL = dictionary[Constants.PlayerFields.pictURL] != nil ? dictionary[Constants.PlayerFields.pictURL] as String! : ""

    }
    
}


//extension SmashTagUser: Equatable {}

//func ==(lhs: SmashTagUser, rhs: SmashTagUser) -> Bool {
//    return lhs.uniqueKey == rhs.uniqueKey
//}

