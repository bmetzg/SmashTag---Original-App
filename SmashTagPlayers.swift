//
//  SmashTagPlayers.swift
//  SmashTag
//
//  Created by Bill on 6/14/17.
//  Copyright © 2017 Google Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class SmashTagDataSource {
    
    static let sharedInstance = SmashTagDataSource()
    
    var playerName = "Anonymous"
    var playerUniqueKey = String()
    var gamePlayerLocation = String()
    
    var playersData = [SmashTagUser]()
    var msglength: NSNumber = 255

    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    let imageCache = NSCache<NSString, UIImage>()
    var placeholderImage = UIImage(named: "ic_account_circle")
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user : FIRUser?

    private init() {} //This prevents others from using the default '()' initializer for this class.
    
    func addPlayerObserver( playersTable : UITableView )
    {
        let ref = FIRDatabase.database().reference().child("messages")
        print ( "add observer \(self.gamePlayerLocation)")
        
        _refHandle = ref.child(self.gamePlayerLocation).observe(.value ) { (snapChat : FIRDataSnapshot) in
            
            print ("in observer")
            var newPlayers: [SmashTagUser] = []
            
            for player in snapChat.children {
                print (player)
                
                let snap = player as! FIRDataSnapshot //each child is a snapshot
                
                if snap.value != nil {
                    print("key ... \(snap.key)")
                    var dict = snap.value as! [String: String] // the value is a dictionary - could be String : Any
                    let name = dict["name"] as! String
                    let text = dict["text"] as! String
                    print("name .... \(name)")
                    print("text .... \(text)")
                    
                    let smashUser = SmashTagUser( dictionary : dict )
                    newPlayers.append(smashUser)
                    
                } else {
                    print("bad snap")
                }
            }
            
            self.playersData = newPlayers
            playersTable.reloadData()
            
        }
        
        return
        
        //  This was crashing on return to TableView and susequent add  .looping through each child one by one
        // insertRows was causing the crash?
        let ref1 = FIRDatabase.database().reference().child("messages")
        
        print ( "add observer \(self.gamePlayerLocation)")
        
        _refHandle = ref1.child(self.gamePlayerLocation).observe(.childAdded ) { (snapChat : FIRDataSnapshot) in
            
            print ("player found at location \(self.gamePlayerLocation)")
            var player = snapChat.value as! [String:String]
            player ["playerIdentifier"] =  snapChat.key
            print (snapChat.key)
            let name = player [Constants.MessageFields.name] ?? "[username]"
            let place_id = player [Constants.MessageFields.name] ?? "[place_id]"
            print ("1")
            let smashUser = SmashTagUser( dictionary: player )
            print("2")
            
            self.playersData.append(smashUser)
            
            print("3 \(self.playersData.count)")
            
            playersTable.insertRows(at: [IndexPath(row: self.playersData.count-1, section : 0)], with: .automatic )
            
            print("4")
            //self.scrollToBottomMessage()
        }
    }
    func removePlayerLocation ( )
    {
        
        //  removes the last currently added by this player - assuming player will only add one?
        print ( "removePlayerLocation \(playerUniqueKey)")
        var ref = FIRDatabase.database().reference()
        ref.child("messages").child(gamePlayerLocation).child(playerUniqueKey).removeValue { error in
            if error != nil {
                print("error \(error)")
            }
            
        }
    }
    
    func addPlayerLocation ( data: [String:String] ) {
        
        print ( "add playerLocation \(self.gamePlayerLocation)")
        
        var ref = FIRDatabase.database().reference()
        
        //ref.child("messages").child(otmPlayersModel.playerLocation).childByAutoId().setValue(data)
        
        let newRef = ref.child("messages").child(self.gamePlayerLocation).childByAutoId()
        newRef.setValue(data)
        
        self.playerUniqueKey = newRef.key
        if self.playerUniqueKey == nil { print ("Error generating player in location/bar database") }
        //  removes the last currently added by this player - assuming player will only add one?
    }
    
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        
        storageRef = FIRStorage.storage().reference()
    }
    
    func deInit() {
        
        print ( "remove observer \(gamePlayerLocation)")

        // need to remove observer or else it will continue after view not active-memory hog
        ref = FIRDatabase.database().reference()
        ref.removeObserver( withHandle: _refHandle)
        
    }
    
    func configureRemoteConfig() {
        // TODO: configure remote configuration settings
        
        let remoteConfigDevSettings = FIRRemoteConfigSettings(developerModeEnabled: true) // allows to change time to pull down a new config setting
        remoteConfig = FIRRemoteConfig.remoteConfig()
        remoteConfig.configSettings = remoteConfigDevSettings!
        
    }
    
    
    func fetchConfig() {
        // TODO: update to the current coniguratation
        
        var expirationDuration : Double = 3600    // 60 minutes
        if remoteConfig.configSettings.isDeveloperModeEnabled {
            expirationDuration = 0
        }
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if status == .success   {
                print ( "remote config friendly_msg_length fetch successful")
                self.remoteConfig.activateFetched()
                let friendlyMsgLength = self.remoteConfig ["friendly_msg_limit"]
                if friendlyMsgLength.source != .static {
                    self.msglength = friendlyMsgLength.numberValue!
                    print ( "friendlyMsgLength changed \(self.msglength)")
                    
                }
                else {
                    print ( "error fetching friendly_msg_length \(String(describing: error))")
                }
            }
        }
    }
    
    func setUpAccessToFireBase() {
        
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
        
    }
    
    func sendMessage(data: [String:String]) {
        // TODO: create method that pushes message to the firebase database
        
        var mdata = data
        // add a key to the data
        //mdata[Constants.MessageFields.name] = playerName
        
        //  "messages/[uniqueautogeneratedtimestamp]"
        print ( "!!" )
        
        print ( data )
        ref.child("messages").childByAutoId().setValue(mdata)
        
        
    }
    
    func sendPhotoMessage(photoData: Data) {
        
        let imagePath = "chat_photos/" + FIRAuth.auth()!.currentUser!.uid + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef!.child(imagePath).put(photoData, metadata : metadata ) { (metadata, error ) in
            if let error = error {
                print ( "error\(error)")
                return
            }
            self.sendMessage(data: [Constants.MessageFields.imageUrl : self.storageRef!.child((metadata?.path)!).description ])
            
        }
    }

}
