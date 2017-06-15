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
    
    // MARK: Initializers
    
    init(dictionary: [String:AnyObject]) {
        
        playerName = dictionary["name"] != nil ? dictionary["name"] as! String! + " " : ""
        playerIdentifier = dictionary["playerIdentifier"] != nil ? dictionary["playerIdentifier"] as! String! + " " : ""
        
    }
    
    static func studentsFromResults(_ results: [[String:AnyObject]]) -> [SmashTagUser] {
        
        var players = [SmashTagUser]()
        
        // iterate through array of dictionaries, each Movie is a dictionary
        for result in results {
            players.append(SmashTagUser(dictionary: result))
            //print ("lastName \(String(describing: students[students.count-1].lastName))  \(students.count)" )
            
        }
        return players
    }
}


//extension SmashTagUser: Equatable {}

//func ==(lhs: SmashTagUser, rhs: SmashTagUser) -> Bool {
//    return lhs.uniqueKey == rhs.uniqueKey
//}

