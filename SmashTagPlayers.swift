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

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let tabController = controller as? UITabBarController {
            return topViewController(controller: tabController.selectedViewController)
        }
        if let navController = controller as? UINavigationController {
            return topViewController(controller: navController.visibleViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
class SmashTagDataSource {
    
    static let sharedInstance = SmashTagDataSource()
    
    var playerUniqueKey = ""
    var gamePlayerLocation = String()
    
    var playerName = "Anonymous"
    var playerScore = 0
    var playerGameState = String()
    var playerState = "active"
    var gamePlayStateChange = false

    var randomPlayerName = "Anonymous"
    var randomPlayerUniqueKey = String()
    
    var playersData = [SmashTagUser]()
    
    var msglength: NSNumber = 255

    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    let imageCache = NSCache<NSString, UIImage>()
    var placeholderImage = UIImage(named: "ic_account_circle")
    
    var _refHandle: FIRDatabaseHandle!
    var _refchildChangedHandle: FIRDatabaseHandle!
    var _refRemoveHandle : FIRDatabaseHandle!
    
    var _authHandle: FIRAuthStateDidChangeListenerHandle!
    
    var user : FIRUser?

    private init() {} //This prevents others from using the default '()' initializer for this class.
    
    func showAlert(title: String, message: String) {
        
        //DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        //}
    }

    
    func addPlayerObserver( playersTable : UITableView, playButton : UIButton, activeGameButton : UIButton )
    {
        
        let ref = FIRDatabase.database().reference().child("playerlocations")
        print ( "add observer \(self.gamePlayerLocation)")
        
        _refHandle = ref.child(self.gamePlayerLocation).observe(.value ) { (snapChat : FIRDataSnapshot) in
            
            print ("in observer a \(self.playersData.count)")
            var newPlayers: [SmashTagUser] = []
            
            for player in snapChat.children {
                print (player)
                
                let snap = player as! FIRDataSnapshot //each child is a snapshot
                
                //if snap.key != self.playerUniqueKey {
                
                if snap.value != nil {
                    print("key ... \(snap.key)")
                    var dict = snap.value as! [String: String] // the value is a dictionary - could be String : Any
                    
                    let name = dict[Constants.PlayerFields.name]
                    
                    print("name .... \(name)")
                    
                    //let playerState = dict[Constants.PlayerFields.playerState] as! String
                    let playerState = dict[Constants.PlayerFields.playerState]

                    let playerGameState = dict[Constants.PlayerFields.playerGameState]
                    
                    var smashUser = SmashTagUser( dictionary : dict )
                    smashUser.playerIdentifier = snap.key
                    
                    print ( "smashUser.playerIdentifier \(smashUser.playerIdentifier)")
                    newPlayers.append(smashUser)
                    
                } else {
                    print("bad snap")
                }
            //    }
            }
            
            self.playersData = newPlayers
            playersTable.reloadData()
            print ("in observer b \(self.playersData.count)")
            
            /*   This is causing it to crash
            if self.playersData.count == 0 { return }
            let bottomMessageIndex = IndexPath(row: playersTable.numberOfRows(inSection: 0) - 1, section: 0)
            playersTable.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
             */
            
        }
        
        let refRemove = FIRDatabase.database().reference().child("playerlocations")
        
        _refRemoveHandle = refRemove.child(self.gamePlayerLocation).observe(.childRemoved ) { (snap : FIRDataSnapshot) in
            guard let playerRemoveKey = snap.value as? String else { return }
            for (index, player) in self.playersData.enumerated() {
                if player.playerIdentifier == playerRemoveKey {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.playersData.remove(at: index)
                    playersTable.deleteRows(at: [indexPath], with: .fade)
                    print ("in observer c remove \(self.playersData.count)")
                }
            }
        }

        ///   need to add
        /*
        usersRef.observe(.childRemoved, with: { snap in
            guard let emailToFind = snap.value as? String else { return }
            for (index, email) in self.currentUsers.enumerated() {
                if email == emailToFind {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.currentUsers.remove(at: index)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        })
        */
        
        _refchildChangedHandle = ref.child(self.gamePlayerLocation).observe(.childChanged ) { (snapChat : FIRDataSnapshot) in
            print ( "in childchanged observer")
            
            var player = snapChat.value as! [String:String]
            
            if self.playerUniqueKey == snapChat.key {
                
                print ("in observer d won lost \(self.playersData.count)")
                
                if player[ Constants.PlayerFields.gamePlayerIdentifier]! != "" {

                //   can't show alert in the main loop????
                switch player [Constants.PlayerFields.playerGameState]! {
                case "won" :    print ("you won! xxx will be buying you a drink")
                                if !self.gamePlayStateChange { return }
                                self.playerGameState = "won"
                                self.gamePlayStateChange = false

                                DispatchQueue.main.async {

                                playButton.isEnabled = true
                                    
                                if let image = UIImage(named: "playwin") {
                                    playButton.setImage(image, for: .normal) //.highlighted  .selected
                                }    
                                activeGameButton.isEnabled = false
                                    
                                self.showAlert (title: "SmashTag! Winner!", message: "\(player[ Constants.PlayerFields.gamePlayerName]!) will buy you a drink!  Once you receive your drink, click Drink Received! to release \(player[ Constants.PlayerFields.gamePlayerName]!) and continue playing.")

                                }
                    
                case "lost":    print ("you lost - you need to by xxxx a drink!")

                                if !self.gamePlayStateChange { return }
                                self.playerGameState = "lost"
                                self.gamePlayStateChange = false
                
                                DispatchQueue.main.async {

                                if let image = UIImage(named: "playlost") {
                                        playButton.setImage(image, for: .normal) //.highlighted  .selected
                                }
                                    
                                playButton.isEnabled = false
                                activeGameButton.isEnabled = false
                                    
                                self.showAlert (title: "SmashTag! Loser!", message: "You will need to buy \(player[ Constants.PlayerFields.gamePlayerName]!) a drink before continuing SmashTag!  \(player[ Constants.PlayerFields.gamePlayerName]!) will release you once they have received their drink.")

                                }
                case "none":    print ("change to none - reenable buttons")
                                self.playerGameState = "none"
                                self.randomPlayerUniqueKey = ""
                                self.randomPlayerName = ""

                                DispatchQueue.main.async {
                                playButton.isEnabled = true
                                activeGameButton.isEnabled = true
                                if let image = UIImage(named: "play") {
                                        playButton.setImage(image, for: .normal) //.highlighted  .selected
                                    }
                                playButton.titleLabel?.text = " Drink! "

                                if let image = UIImage(named: "drinkactive") {
                                        activeGameButton.setImage(image, for: .normal) //.highlighted  .selected
                                    }

                                }
                default : break
                }
                    
                }
            }
        }
        
        return
        
        //  This was crashing on return to TableView and susequent add  .looping through each child one by one
        // insertRows was causing the crash?
        let ref1 = FIRDatabase.database().reference().child("playerlocations")
        
        print ( "add child changed observer \(self.gamePlayerLocation)")
        
        _refHandle = ref1.child(self.gamePlayerLocation).observe(.childChanged ) { (snapChat : FIRDataSnapshot) in
            
            print ("player found at location \(self.gamePlayerLocation)")
            var player = snapChat.value as! [String:String]
            player ["playerIdentifier"] =  snapChat.key
            print (snapChat.key)
            let name = player [Constants.PlayerFields.name] ?? "[username]"
            let place_id = player [Constants.PlayerFields.name] ?? "[place_id]"
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
        let ref = FIRDatabase.database().reference()
        ref.child("playerlocations").child(gamePlayerLocation).child(playerUniqueKey).removeValue { error in
            if error != nil {
                print("error \(error)")
            }
            
        }
    }
    
    func addPlayerLocation ( data: [String:String] ) {
        
        print ( "add playerLocation \(self.gamePlayerLocation)")
        
        let ref = FIRDatabase.database().reference()
        
        //ref.child("playerlocations").child(otmPlayersModel.playerLocation).childByAutoId().setValue(data)
        
        let newRef = ref.child("playerlocations").child(self.gamePlayerLocation).childByAutoId()
        newRef.setValue(data)
        
        self.playerUniqueKey = newRef.key
        if self.playerUniqueKey == nil { print ("Error generating player in location/bar database") }

    }
    
    func addAnotherPlayerLocation ( data: [String:String] ) {
        
        print ( "add playerLocation \(self.gamePlayerLocation)")
        
        let ref = FIRDatabase.database().reference()
        
        //ref.child("playerlocations").child(otmPlayersModel.playerLocation).childByAutoId().setValue(data)
        
        let newRef = ref.child("playerlocations").child(self.gamePlayerLocation).childByAutoId()
        newRef.setValue(data)
        
        
        //self.playerUniqueKey = newRef.key
        
        if self.playerUniqueKey == nil { print ("Error generating player in location/bar database") }

    }
    
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        
        storageRef = FIRStorage.storage().reference()
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
        // fetchConfig()   - use this in future to do custom config?  BM
        
    }
    
    func returnCurrentPlayer() -> Int {
        
        for (index, player) in self.playersData.enumerated() {
            if player.playerIdentifier == self.playerUniqueKey {
                return index
            }

        }
        return 0

    }

    func savePlayerPhoto (photoData: Data) {
        
        let imagePath = "chat_photos/" + FIRAuth.auth()!.currentUser!.uid + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"

        self.storageRef!.child(imagePath).put(photoData, metadata : metadata ) { (metadata, error ) in
            if let error = error {
                print ( "error\(error)")
                return
            }
            
        let ref = FIRDatabase.database().reference().child("playerlocations")
        let playerref = ref.child(self.gamePlayerLocation).child(self.playerUniqueKey)
        let updatedPlayerData = self.playersData[self.returnCurrentPlayer()]
            
        playerref.setValue([Constants.PlayerFields.name: updatedPlayerData.playerName,
                                Constants.PlayerFields.playerState: updatedPlayerData.playerState,
                                Constants.PlayerFields.playerGameState : updatedPlayerData.playerGameState,
                                Constants.PlayerFields.gamePlayerIdentifier : updatedPlayerData.gamePlayerIdentifier,
                                Constants.PlayerFields.gamePlayerName : updatedPlayerData.gamePlayerName,
                                Constants.PlayerFields.pictURL : self.storageRef!.child((metadata?.path)!).description])
        }
    }
}
    
