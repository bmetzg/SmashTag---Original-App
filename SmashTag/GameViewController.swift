
import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import GooglePlacePicker
import MessageUI
import SpriteKit

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


class GameViewController: UIViewController, UINavigationControllerDelegate {
    
    var keyboardOnScreen = false
    
    let imageCache = NSCache<NSString, UIImage>()
    var placeholderImage = UIImage(named: "ic_account_circle")
    var placeholderImageInactive = UIImage(named: "ic_account_circle_inactive")

    let smashPlayersModel = SmashTagDataSource.sharedInstance
    
    var playerState = "active"
    
    // MARK: Outlets

    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var activityOutlet: UIActivityIndicatorView!
    @IBOutlet weak var playSmashTagOutlet: UIButton!
    @IBOutlet weak var inTheGameOutlet: UIButton!

    @IBOutlet weak var messagesTable: UITableView!
    
    // MARK: Life Cycle
    
     func deinitAll () {
        
        print ( "deinit remove observer \(smashPlayersModel.gamePlayerLocation)")
        
        NotificationCenter.default.removeObserver(self)
        // resign active observer added in view did load
        
        // need to remove observer or else it will continue after view not active-memory hog
        
        //let ref = FIRDatabase.database().reference()
        let ref = FIRDatabase.database().reference().child("playerlocations")
 
        ref.removeObserver( withHandle: smashPlayersModel._refHandle)
        ref.removeObserver( withHandle: smashPlayersModel._refchildChangedHandle)
        ref.removeObserver( withHandle: smashPlayersModel._refRemoveHandle)
        
        print ( "deinit remove observer end \(smashPlayersModel.gamePlayerLocation)")
        
        smashPlayersModel.removePlayer ( player: smashPlayersModel.playerUniqueKey)

        for player in smashPlayersModel.playersAdded {
            smashPlayersModel.removePlayer( player: player )
        }
        
        let defaults = UserDefaults.standard
        defaults.set(smashPlayersModel.playerScore, forKey: "score")
        
        defaults.set(smashPlayersModel.blockUsers, forKey: "block")
        
        defaults.synchronize()
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        activityOutlet.isHidden = true
        
        let data = [Constants.PlayerFields.name: smashPlayersModel.playerName,
                    Constants.PlayerFields.playerState: "active",
                    Constants.PlayerFields.playerGameState : "none",
                    Constants.PlayerFields.gamePlayerIdentifier : "",
                    Constants.PlayerFields.gamePlayerName : "",
                    Constants.PlayerFields.pictURL : "",
                    Constants.PlayerFields.score : "\(smashPlayersModel.playerScore)"
        ]
        
        
        smashPlayersModel.addPlayerLocation ( data: data )

        smashPlayersModel.playersData.removeAll()
        smashPlayersModel.playersData = []
        self.messagesTable.reloadData()
        
        /*
         in future - change strings to enum/integer values
         let groceryItem = GroceryItem(name: text,
         addedByUser: self.user.email,
         completed: false)
         let groceryItemRef = self.ref.child(text.lowercased())
         groceryItemRef.setValue(groceryItem.toAnyObject())
        */
        
        smashPlayersModel.addPlayerObserver( playersTable: messagesTable,  playButton: playSmashTagOutlet, activeGameButton: inTheGameOutlet )
        
        /*
        var image1:UIImage = UIImage(named: "play")!
        var image2:UIImage = UIImage(named: "drinkb")!
        var image3:UIImage = UIImage(named: "drinkc")!
        var image4:UIImage = UIImage(named: "drinkd")!
 
        playSmashTagOutlet.setImage(image1, for: [])
        
        playSmashTagOutlet!.imageView!.animationImages = [image1, image2, image3, image4]
        playSmashTagOutlet!.imageView!.animationDuration = 100.0
         */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil)
    

    }
    
    @objc func applicationWillResignActive(notification: NSNotification) {
        //  works - except alert is brought up - AFTER going into the background
        //  
        //signOut(signOutButton)
    }

    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)
        // viewwilldisappear
    }
    
    override func viewWillAppear(_ animated: Bool) {
    
    super.viewWillAppear(animated)
    }
    

    func showAlert(title: String, message: String) {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Scroll Messages
    
    func scrollToBottomMessage() {
        
        if smashPlayersModel.playersData.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: messagesTable.numberOfRows(inSection: 0) - 1, section: 0)
        messagesTable.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
  
    }
    
    // MARK: Actions
    @IBAction func inTheGameButton(_ sender: Any) {
        
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }
        
        print ("player state \(self.playerState)")
        //smashPlayersModel.gamePlayStateChange = false
        
        if self.playerState == "active" {
            DispatchQueue.main.async {

            if let image = UIImage(named: "drinkinactive") {
                self.inTheGameOutlet.setImage(image, for: .normal) //.highlighted  .selected
            }
            self.playerState = "notActive"
            }

            setPlayerNotActive ( uniqueKey: smashPlayersModel.playerUniqueKey )
            playSmashTagOutlet.isEnabled = false
        }
        else {
            DispatchQueue.main.async {

            if let image = UIImage(named: "drinkactive") {
                self.inTheGameOutlet.setImage(image, for: .normal) //.highlighted  .selected
            }
            self.playerState = "active"
            }
            setPlayerActive ( uniqueKey: smashPlayersModel.playerUniqueKey )
            playSmashTagOutlet.isEnabled = true

        }
    }

    @IBAction func didTapAddPhoto(_ sender: AnyObject) {
        var name : String
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }

        // BM need to remove

        //smashPlayersModel.playerScore = 0

        let x = Int(arc4random_uniform(9))
        
        switch x {
        case 0 : name = "zero"
        case 1 : name = "squiggy92"
        case 2 : name = "beer pong"
        case 3 : name = "ScottM"
        case 4 : name = "SurfRider 1999"
        case 5 : name = "smashtag!_player_"
        case 6 : name = "Subway Bar player"
        case 7 : name = "Timmy"
        case 8 : name = "Meagan Hi!"
        case 9 : name = "Hello?"
        default : name = "Drink Round Buyer"
        }
        //"smashtag!_player_\(smashPlayersModel.playersData.count+1)"
        let data = [Constants.PlayerFields.name: name,
                    Constants.PlayerFields.playerState: "active",
                    Constants.PlayerFields.playerGameState : "none",
                    Constants.PlayerFields.gamePlayerIdentifier : "",
                    Constants.PlayerFields.gamePlayerName : "",
                    Constants.PlayerFields.pictURL : "",
                    Constants.PlayerFields.score : "\(0)"

        ]

        smashPlayersModel.addAnotherPlayerLocation(data: data )
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
        
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        
        var messageText = String()
        /*
        let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.smashPlayersModel.connectedToInternet = true
            } else {
                self.smashPlayersModel.connectedToInternet = false
            }
        })Noise Control Administrator
        */
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }
        
        switch smashPlayersModel.playerGameState {
        case "lost"  : messageText = "You need to buy another player a drink before signing out.  Exiting now will result in a penalty."
                       smashPlayersModel.playerScore = smashPlayersModel.playerScore - 1

        case "won"  :  messageText = "Another player owes you a drink.  Exiting now will cause you to forfeit this drink."
            
        default : messageText = "Sorry to see you leave the Game!"
                  break
        }
        
        let signoutAlert = UIAlertController(title: "Smash Tag!", message: messageText, preferredStyle: UIAlertControllerStyle.alert)
        
        signoutAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { (action: UIAlertAction!) in
            
        if self.smashPlayersModel.connectedToInternet {
            
            print ("sign out")
            self.smashPlayersModel.releaseGamePlayers (whichPlayertoRelease: self.smashPlayersModel.playerUniqueKey, remove: true)

            self.deinitAll()

            do {
                try FIRAuth.auth()?.signOut()
                self.dismiss(animated: true)

            } catch {
                print ("sign out error ")
                self.showAlert(title: "Sign Out", message: "Unable to sign out")

            }
        }
        }))
        
        signoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            return
        }))
        
        present(signoutAlert, animated: true, completion: nil)
        
        /*
        do {
            self.dismiss(animated: true, completion: nil )
            try FIRAuth.auth()?.signOut()

        } catch {
            showAlert(title: "Sign Out", message: "Unable to sign out \(error)")        }
        */
        
    }
    
    @IBAction func playSmashTag(_ sender: Any) {
        var playerWinVal = String()
        var randomWinVal = String()
        
            
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }

        
        if smashPlayersModel.playerGameState == "won" {
            print ("release game players")
            smashPlayersModel.releaseGamePlayers (whichPlayertoRelease: smashPlayersModel.playerUniqueKey, remove: false)
        }
        else
        {

            var scene: AnimationScene!
            var size: CGSize!
            
            let mySKView = SKView(frame: self.view.frame)
            
            mySKView.alpha = 0.5

            //self.navigationController?.view.addSubview(mySKView)
            self.view?.addSubview(mySKView)
            
            
            size = self.view.frame.size
            scene = AnimationScene(size: size)

            mySKView.presentScene( scene )
            

            
            var activePlayers = constructActivePlayerList ()

            if activePlayers.count >= 1 {
            
                let randomWin = Int(arc4random_uniform(2))
            
                switch randomWin {
                case 0  :   playerWinVal = "lost"
                            smashPlayersModel.playerScore = smashPlayersModel.playerScore - 1
                randomWinVal = "won"
                case 1  :   playerWinVal = "won"
                            smashPlayersModel.playerScore = smashPlayersModel.playerScore + 1

                randomWinVal = "lost"
                default : break
                }
                let randomplayer = arc4random_uniform(UInt32(activePlayers.count))

                smashPlayersModel.randomPlayerUniqueKey = activePlayers[Int(randomplayer)].playerIdentifier
                smashPlayersModel.randomPlayerName = activePlayers[Int(randomplayer)].playerName
                
                //  get unique identifier of random player
                //  setvalue of random user unique identifier to random index
                //  setvalue of player unique identifier to !random index
            
                //  implement observer on change of playerstate to do check if won or lost and implement a procedure
            
                let ref = FIRDatabase.database().reference()
            
                // GAME PLAYER
                let playerref = ref.child("playerlocations").child(smashPlayersModel.gamePlayerLocation).child(smashPlayersModel.playerUniqueKey)
            
                smashPlayersModel.playerGameState = playerWinVal
                //let newName = setPlayerNamewScore ( playerName: smashPlayersModel.playerName.components(separatedBy: " " )[0] )
                //smashPlayersModel.playerName = newName
                
                smashPlayersModel.gamePlayStateChange = true

                playerref.updateChildValues([
                    Constants.PlayerFields.playerGameState: playerWinVal,
                    Constants.PlayerFields.gamePlayerIdentifier:smashPlayersModel.randomPlayerUniqueKey,
                    Constants.PlayerFields.gamePlayerName:smashPlayersModel.randomPlayerName,
                    Constants.PlayerFields.playerState:"notActive",
                    Constants.PlayerFields.score:"\(smashPlayersModel.playerScore)"
                                        ])
            
            //RANDOM GAME PLAYER
            
                let playerref2 = ref.child("playerlocations").child(smashPlayersModel.gamePlayerLocation).child(activePlayers[Int(randomplayer)].playerIdentifier)
                
                playerref2.observeSingleEvent(of: .value, with: { (snapshot) in
                    for snap in snapshot.children {
                    let snap = snapshot //each child is a snapshot
                    
                    if snap.key == activePlayers[Int(randomplayer)].playerIdentifier {
                    
                    if snap.value != nil {
                        print("key ... \(snap.key)")
                        var dict = snap.value as! [String: String] // the value is a dictionary - could be String : Any
                        var score = Int(dict[Constants.PlayerFields.score]!)
                        
                        switch randomWin {
                        case 0  :   score = score! + 1
                        case 1  :   score = score! - 1
                        default : break
                        }

                    playerref2.updateChildValues([
                    Constants.PlayerFields.playerGameState:randomWinVal,
                    Constants.PlayerFields.gamePlayerIdentifier:self.smashPlayersModel.playerUniqueKey,
                    Constants.PlayerFields.gamePlayerName:self.smashPlayersModel.playerName,
                    Constants.PlayerFields.playerState:"notActive",
                    Constants.PlayerFields.score:"\(score!)"

                                            ])

                    }
                        }
                    }
                })
                
            }
            else {
            showAlert (title: "Smash Tag!", message: "Not enough players at the bar to play Smash Tag!")
            }
        }
    }
    
    func setPlayerNamewScore ( playerName : String, score : Int32 )  -> String {
        var i : Int32 = 1

        var newplayerName = playerName
        
        if score <= -1 {
            i = i * -1
            newplayerName = playerName + " "
            while i >= score {
                newplayerName = newplayerName + "🥛"
                i = i - 1
            }
        }
        else if score > 0
        {
            newplayerName = playerName + " "
            while i <= score {
                newplayerName = newplayerName + " 🍺"
                i = i + 1
            }
        }
        return newplayerName
    }
    
    func setPlayerActive ( uniqueKey : String )  {
        
        let ref = FIRDatabase.database().reference()
        
        let playerref = ref.child("playerlocations").child(smashPlayersModel.gamePlayerLocation).child(uniqueKey)
        let playerGameStateRef = playerref.child(Constants.PlayerFields.playerState)
        playerGameStateRef.setValue("active")
        
    }

    func setPlayerNotActive ( uniqueKey : String )  {
        
    let ref = FIRDatabase.database().reference()

    let playerref = ref.child("playerlocations").child(smashPlayersModel.gamePlayerLocation).child(uniqueKey)
    let playerGameStateRef = playerref.child(Constants.PlayerFields.playerState)
        playerGameStateRef.setValue("notActive")

    }
    
    func constructActivePlayerList () -> [SmashTagUser] {
    var activePlayersData = [SmashTagUser]()
        
        for player in smashPlayersModel.playersData {
            print ( player.playerState )
            if player.playerState == "active" {
                //print ("player.playerState \(player.playerState)")
                //print ("otmPlayersModel.playerUniqueKey \(smashPlayersModel.playerUniqueKey)")

                if player.playerIdentifier != smashPlayersModel.playerUniqueKey {
                    activePlayersData.append(player) }
                }
        }
    return activePlayersData
    }

}

// MARK: - FCViewController: UITableViewDelegate, UITableViewDataSource

extension GameViewController: UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return smashPlayersModel.playersData.count
        
    }
    
    func numberOfSectionsInTableView(tableView:UITableView!)->Int
    {
        return 1
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }


    func tableView( _ tableView : UITableView, didSelectRowAt: IndexPath) {
        
        tableView.deselectRow(at: didSelectRowAt, animated: false)
        
        if smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier != smashPlayersModel.playerUniqueKey
        {
            
            func someHandler(alert: UIAlertAction!) {
                
                if alert.title == "Block Player" {
                    smashPlayersModel.blockUsers.append(smashPlayersModel.playersData[didSelectRowAt.row].playerName)
                    
                    if smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier == smashPlayersModel.randomPlayerUniqueKey{
                        smashPlayersModel.releaseGamePlayers (whichPlayertoRelease: smashPlayersModel.playerUniqueKey, remove: false )
                    }
                    
                    smashPlayersModel.playersData.remove(at: didSelectRowAt.row)
                    messagesTable.deleteRows(at: [didSelectRowAt], with: .fade)
                    //
                }
                if alert.title == "Report Player" {
                    
                    let messageString = "Player " + smashPlayersModel.playersData[didSelectRowAt.row].playerName + " " + smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier + " at location " + smashPlayersModel.gamePlayerLocation + " is being reported for possibly offending material."
                        
                    smashPlayersModel.releaseGamePlayers (whichPlayertoRelease: smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier, remove: true)
                    smashPlayersModel.removePlayer(player: smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier)

                    if !MFMailComposeViewController.canSendMail() {
                        showAlert(title: "Error", message: "Mail services are not available")
                        return
                    }

                    let mailVC = MFMailComposeViewController()
                    mailVC.mailComposeDelegate = self
                    mailVC.setToRecipients(["shorewalkowner@gmail.com"])
                    mailVC.setSubject("Report Offending SmashTag! Material/Player")
                    mailVC.setMessageBody(messageString, isHTML: false)
                    
                    present(mailVC, animated: true, completion: nil)
                }
                if alert.title == "Remove Player" {
                    smashPlayersModel.releaseGamePlayers (whichPlayertoRelease: smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier, remove: true)
                    smashPlayersModel.removePlayer(player: smashPlayersModel.playersData[didSelectRowAt.row].playerIdentifier)
                }

            }
            
            let alert = UIAlertController()
            alert.title = "Block, Remove, or Report a SmashTag! Player"
            alert.message = "Block a Player\n Block a Player from your SmashTag! Game.  The Player will remain an active SmashTag! player but will no longer be in your SmashTag! Game.  This can also be used if a drink won from a player is not received.  You will be returned to the game and the negligent player will be removed/blocked. \n Remove a Player \n Remove a Player from SmashTag!  The Player will be removed from SmashTag! Use this for possible offensive material without reporting the Player.\n Report a Player \n Report a Player for offensive material.  The Player will be removed from SmashTag! immediately.  We strongly enforce a no tolerance policy for objectionable content. If you see inappropriate content, please use “Report Player”.\n"
            
            
            alert.addAction(UIAlertAction(title: "Block Player", style: UIAlertActionStyle.default, handler: someHandler ))
            alert.addAction(UIAlertAction(title: "Remove Player", style: UIAlertActionStyle.default, handler: someHandler))
            alert.addAction(UIAlertAction(title: "Report Player", style: UIAlertActionStyle.default, handler: someHandler))

            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: someHandler))
            self.present(alert, animated: true)
            
        }
        
    }
    
    func convertImageToBW(image:UIImage) -> UIImage {
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        
        // convert UIImage to CIImage and set as input
        
        let ciInput = CIImage(image: image)
        filter?.setValue(ciInput, forKey: "inputImage")
        
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        
        return UIImage(cgImage: cgImage!)
    }
    
    @objc func photoTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
    if tapGestureRecognizer.state == .ended {
        let imgView = tapGestureRecognizer.view as! UIImageView
        print("your taped image view tag is : \(imgView.tag)")
            
        let alert = UIAlertController(title: smashPlayersModel.playersData[imgView.tag].playerName, message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        print ( alert.title )
        if !(smashPlayersModel.playersData[imgView.tag].photo?.isEmpty)! {
            
            alert.message = ""
        
            alert.addPhoto(image: UIImage.init(data: smashPlayersModel.playersData[imgView.tag].photo!, scale : 1 )!)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default , handler: nil ))
    
            self.present(alert, animated: true)
        }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("tableview row insert \(indexPath.row)")

        // dequeue cell
        let cell: UITableViewCell! = messagesTable.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        
        let smashUser : SmashTagUser! = smashPlayersModel.playersData[indexPath.row]
        let name = smashUser.playerName
        var newName = setPlayerNamewScore ( playerName: name, score: smashUser.score )
        
        print ( "\(name) \(smashUser.score)")
        let imageURL = smashUser.pictURL
        
        if imageURL != ""
        {
            cell.textLabel?.text = newName
            if smashUser.playerState == "active" {
                cell.textLabel?.alpha=1.0
                print ("alpha 1.0 Row \(indexPath.row)")
                
            }
            else {
                print ("alpha .4 Row \(indexPath.row)")
                cell.textLabel?.alpha=0.4
            }

            //download and display the image
            FIRStorage.storage().reference(  forURL : imageURL! ).data(withMaxSize: INT64_MAX ){ (data, error) in
                guard error == nil else {
                    print ( "error returning image \(String(describing: error))")
                    if smashUser.playerState == "active" {
                        cell.textLabel?.alpha=1.0
                        cell.imageView?.image = self.placeholderImage }
                    else{
                        cell.textLabel?.alpha=0.4
                        cell.imageView?.image = self.placeholderImageInactive
                    }

                    return
                }
                print ("alpha download picture  \(indexPath.row)")

                DispatchQueue.main.async {
                        let messageimage = UIImage.init(data: data!, scale : 1 )   //   setting image to width of 50 before saving
                        //let messageimage = UIImage.init(data: data!, scale : 50 )

                        self.smashPlayersModel.playersData[indexPath.row].photo = data
                        let cellmessageimage = messageimage?.resized(toWidth: 50 )
                        cell.imageView?.image = cellmessageimage
                        //cell.textLabel?.text = newName
                        cell.setNeedsLayout()
                }
            }
        }
        else {
            DispatchQueue.main.async {

            if smashUser.playerState == "active" {
                    cell.textLabel?.alpha=1.0
                    cell.imageView?.image = self.placeholderImage }
                else{
                    cell.textLabel?.alpha=0.4
                    cell.imageView?.image = self.placeholderImageInactive
                }
                cell.textLabel?.text = newName
            }

        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(photoTapped(tapGestureRecognizer:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        cell?.imageView?.isUserInteractionEnabled = true
        cell?.imageView?.tag = indexPath.row
        cell?.imageView?.addGestureRecognizer(tapGestureRecognizer)
        
        return cell!

        // TODO: update cell to display message data
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
        
}

// MARK: - FCViewController: UIImagePickerControllerDelegate

extension GameViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        
        /*
        let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.smashPlayersModel.connectedToInternet = true
            } else {
                self.smashPlayersModel.connectedToInternet = false
            }
        })
        */

        // constant to hold the information about the photo
        if let photo = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            //let myThumb1 = photo.resized(withPercentage: 0.1)
            //let mySmallPhoto = photo.resized(toWidth: 50)
            
            let mySmallPhoto = photo.resized(toWidth: 250)
            let photoData = UIImageJPEGRepresentation(mySmallPhoto!, 0.8)   // compression

            if smashPlayersModel.savePlayerPhoto( photoData: photoData!, activityIndicator: activityOutlet )
                != 0 { showAlert(title: "Photo save error", message: "Your photo was not saved due to a network error")
            }


        }
        
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Photo Save Error", message: "User is not connected to the internet. Please check your network connection and try again")
        }

        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FCViewController: UITextFieldDelegate

extension GameViewController: UITextFieldDelegate {
        
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            self.view.frame.origin.y -= self.keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            self.view.frame.origin.y += self.keyboardHeight(notification)
        }
    }
    
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        return ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
    }
    
    /*
    func resignTextfield() {
        if messageTextField.isFirstResponder {
            messageTextField.resignFirstResponder()
        }
    }
    */
    
}

// MARK: - FCViewController (Notifications)

extension GameViewController {
    
    func subscribeToKeyboardNotifications() {
        /*
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
        */
    }
    
    func subscribeToNotification(_ name: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

