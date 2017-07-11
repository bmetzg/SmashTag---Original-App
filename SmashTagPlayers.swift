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
    var playerGameState = "none"
    var playerState = "active"
    var gamePlayStateChange = false  // removE

    var randomPlayerName = "Anonymous"
    var randomPlayerUniqueKey = String()
    
    var playersData = [SmashTagUser]()
    var playersAdded = [ String ]()
    
    var msglength: NSNumber = 255

    var ref: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    let imageCache = NSCache<NSString, UIImage>()
    var placeholderImage = UIImage(named: "ic_account_circle")
    
    var _refHandle: FIRDatabaseHandle!
    var _refchildChangedHandle: FIRDatabaseHandle!
    var _refRemoveHandle : FIRDatabaseHandle!
    var _internetConnectionHandle : FIRDatabaseHandle!
    
    var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var connectedToInternet : Bool = true
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

        
        _refHandle = ref.child(self.gamePlayerLocation).observe(.value ) { (snapChat : FIRDataSnapshot) in
            
            print ("in observer a \(self.playersData.count)")
            var newPlayers: [SmashTagUser] = []
            
            for player in snapChat.children {
                print ("in observer a \(player)")
                
                let snap = player as! FIRDataSnapshot //each child is a snapshot
                
                //if snap.key != self.playerUniqueKey {
                
                if snap.value != nil {
                    print("key ... \(snap.key)")
                    var dict = snap.value as! [String: String] // the value is a dictionary - could be String : Any
                    /*
                    let name = dict[Constants.PlayerFields.name]
                    let playerState = dict[Constants.PlayerFields.playerState]
                    let playerGameState = dict[Constants.PlayerFields.playerGameState]
                    */
                    var smashUser = SmashTagUser( dictionary : dict )
                    smashUser.playerIdentifier = snap.key
                    
                    newPlayers.append(smashUser)
                    
                } else {
                    print("bad snap")
                }
            //}
            }
            
            self.playersData = newPlayers
            playersTable.reloadData()
            
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
        
        let refChild = FIRDatabase.database().reference().child("playerlocations")
        _refchildChangedHandle = refChild.child(self.gamePlayerLocation).child(self.playerUniqueKey).observe(.childChanged ) { (snapChat : FIRDataSnapshot) in
            print ( "in observer d \(snapChat.value) \(snapChat.key)")
            
            // active notActive
            /*
            if snapChat.key == Constants.PlayerFields.playerState {
                if snapChat.value as! String == "active" {
                    DispatchQueue.main.async {
                        playButton.isEnabled = true
                        activeGameButton.isEnabled = true
                        if let image = UIImage(named: "drinkactive") {
                            activeGameButton.setImage(image, for: .normal) //.highlighted  .selected
                        }
                        
                    }
                    self.playerGameState = "none"
                    self.playerState = "active"

                }
                else
                {
                    DispatchQueue.main.async {
                        playButton.isEnabled = false
                        activeGameButton.isEnabled = true
                        if let image = UIImage(named: "drinkinactive") {
                            activeGameButton.setImage(image, for: .normal) //.highlighted  .selected
                        }
                        
                    }
                    self.playerGameState = "none"
                    self.playerState = "notActive"
                }
            }
            */
            
            // randomPlayerUniqueKey
            if snapChat.key == Constants.PlayerFields.gamePlayerIdentifier {
                self.randomPlayerUniqueKey = snapChat.value as! String
                print ("setting random key")
            }
            
            if snapChat.key == Constants.PlayerFields.gamePlayerName {
                self.randomPlayerName = snapChat.value as! String
                print ("setting random name")
            }
            
            // game state won lost none
            if snapChat.key == Constants.PlayerFields.playerGameState {
                
                print ("in observer d won lost \(self.playersData.count)")
                
                //   can't show alert in the main loop????
                switch snapChat.value as! String {
                case "won" :    print ("you won! xxx will be buying you a drink")
                
                //if !self.gamePlayStateChange { return }
                self.playerGameState = "won"
                self.gamePlayStateChange = false
                
                //self.randomPlayerUniqueKey = snapChat.value as! String
                
                DispatchQueue.main.async {
                    
                    playButton.isEnabled = true
                    
                    if let image = UIImage(named: "playwin") {
                        playButton.setImage(image, for: .normal) //.highlighted  .selected
                    }
                    activeGameButton.isEnabled = false

                    var name = self.randomPlayerName.components(separatedBy: " ")[0]
                    if name == "" {name = self.randomPlayerName }
                    
                    self.showAlert (title: "SmashTag! Winner!", message: "\(name) will buy you a drink!  Once you receive your drink, click Drink Received! to release \(name) and continue playing.")
                    
                    }
                    
                case "lost":    print ("you lost - you need to by xxxx a drink!")

                //if !self.gamePlayStateChange { return }
                self.playerGameState = "lost"
                self.gamePlayStateChange = false
                
                DispatchQueue.main.async {
                    
                    if let image = UIImage(named: "playlost") {
                        playButton.setImage(image, for: .normal) //.highlighted  .selected
                    }
                    
                    playButton.isEnabled = false
                    activeGameButton.isEnabled = false
                    
                    var name = self.randomPlayerName.components(separatedBy: " ")[0]
                    if name == "" {name = self.randomPlayerName }

                    self.showAlert (title: "SmashTag! Loser!", message: "You will need to buy \(name) a drink before continuing SmashTag!  \(name) will release you once they have received their drink.")
                    
                    if  self.randomPlayerName.contains("smashtag!_player") { self.releaseGamePlayers() }
                    
                    }
                    
                case "none":    print ("none - reenable buttons")

                print ("none - reenable buttons 2")

                DispatchQueue.main.async {
                    playButton.isEnabled = true
                    activeGameButton.isEnabled = true
                    if let image = UIImage(named: "play") {
                        playButton.setImage(image, for: .normal) //.highlighted  .selected
                    }
                    if let image = UIImage(named: "drinkactive") {
                        activeGameButton.setImage(image, for: .normal) //.highlighted  .selected
                    }
                    
                }
                self.playerGameState = "none"
                self.playerState = "active"
                    
                    
                default : break
                }
            }

            }
    
    }
    
    func releaseGamePlayers() {
        
        let ref = FIRDatabase.database().reference()
        
        //RANDOM GAME PLAYER
        if self.randomPlayerUniqueKey != "" {
            print ("setting game stat to none \(self.randomPlayerUniqueKey)")
            let playerref2 = ref.child("playerlocations").child(self.gamePlayerLocation).child(self.randomPlayerUniqueKey)
        
            playerref2.updateChildValues([Constants.PlayerFields.playerGameState:"none",
                                        Constants.PlayerFields.gamePlayerIdentifier:"",
                                        Constants.PlayerFields.gamePlayerName:"",
                                        Constants.PlayerFields.playerState:"active"
            ])
        }
        // GAME PLAYER
        if self.playerUniqueKey != "" {
           let playerref = ref.child("playerlocations").child(self.gamePlayerLocation).child(self.playerUniqueKey)
        
            playerref.updateChildValues([Constants.PlayerFields.playerGameState: "none",
                                       Constants.PlayerFields.gamePlayerIdentifier:"",
                                       Constants.PlayerFields.gamePlayerName:"",
                                       Constants.PlayerFields.playerState:"active"
            ])
            //smashPlayersModel.gamePlayStateChange = true
            self.playerGameState = "none"
        }
        
        self.randomPlayerUniqueKey = ""
        self.randomPlayerName = ""
        
    }

    func removePlayer ( player : String )
    {
        if player == "" { return }
            
        //  removes the last currently added by this player - assuming player will only add one?
        print ( "removePlayerLocation \(player)")
        let ref = FIRDatabase.database().reference()
        ref.child("playerlocations").child(gamePlayerLocation).child(player).removeValue { error in
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
        
        self.playersAdded.append ( newRef.key )

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
    
    func savePlayerPhoto (photoData: Data, activityIndicator : UIActivityIndicatorView ) -> Int {
        var myerror : Int = 0
        let imagePath = "chat_photos/" + FIRAuth.auth()!.currentUser!.uid + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        self.storageRef!.child(imagePath).put(photoData, metadata : metadata ) { (metadata, error ) in
            DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            }
            if let error = error {
                print ( "error\(error)")
                myerror = -1
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true

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
        return myerror
    }

}

