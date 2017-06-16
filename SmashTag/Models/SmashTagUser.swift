//
//  File.swift
//  SmashTag
//
//  Created by Bill on 6/14/17.
//  Copyright © 2017 Google Inc. All rights reserved.
//


//

struct SmashTagUser {
    
    // MARK: Properties
    
    let playerName : String
    let playerIdentifier : String?
    let imageURL : String? = nil
    
    // MARK: Initializers
    
    init(dictionary: [String:String]) {
        
        playerName = dictionary["name"] != nil ? dictionary["name"] as! String! + " " : ""
        
        playerIdentifier = dictionary["playerIdentifier"] != nil ? dictionary["playerIdentifier"] as! String! + " " : ""
        
    }
    
}


//extension SmashTagUser: Equatable {}

//func ==(lhs: SmashTagUser, rhs: SmashTagUser) -> Bool {
//    return lhs.uniqueKey == rhs.uniqueKey
//}

