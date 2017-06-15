//
//  SmashTagPlayers.swift
//  SmashTag
//
//  Created by Bill on 6/14/17.
//  Copyright © 2017 Google Inc. All rights reserved.
//

import Foundation

class SmashTagDataSource {
    
    static let sharedInstance = SmashTagDataSource()
    
    var playersData = [SmashTagUser]()
    
    private init() {} //This prevents others from using the default '()' initializer for this class.
    
    
}
