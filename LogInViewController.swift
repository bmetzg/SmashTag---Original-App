//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import GooglePlacePicker
import CoreLocation


class LogInViewController: UIViewController, UINavigationControllerDelegate, CLLocationManagerDelegate {
    private var placePicker: GMSPlacePicker?
    var mapViewController: BackgroundMapViewController?
    
    var locManager: CLLocationManager!

    // MARK: Properties
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 255
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    let imageCache = NSCache<NSString, UIImage>()
    var keyboardOnScreen = false
    var placeholderImage = UIImage(named: "ic_account_circle")
    fileprivate var _refHandle: FIRDatabaseHandle!
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"
    
    // MARK: Outlets
    
    @IBOutlet weak var locateMeButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!

    @IBOutlet var dismissImageRecognizer: UITapGestureRecognizer!
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var gameLocationLable: UILabel!
    @IBOutlet weak var playGameButton: UIButton!

    @IBAction func locateMeAction(_ sender: Any) {
        pickAPlace()
   }
    @IBAction func playGameButton(_ sender: Any) {
        pickAPlace()
  }

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        
        super .viewDidLoad()
        //self.signedInStatus(isSignedIn: true)
        // this allowed users to sign in anonymously
        //replaceing this with authentication - bm
        
        self.user = nil
        // bm remove to enable login of active user
        
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        
        configureAuth()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super .viewDidAppear(animated)
        
        returnCurrentBus()

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: Config
    
    func configureAuth() {
        // Listens for changes in the authorization state
        
        let provider:[FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        //
        
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth : FIRAuth, user : FIRUser? ) in
            print ("signed in?")
            //self.messages.removeAll()
            //self.messagesTable.reloadData()
            
            if let activeUser = user {
                if self.user != activeUser {
                    print ("signed in")

                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                }
                return

            }
            print ("not signed in")
            self.signedInStatus(isSignedIn: false)
            self.loginSession()
        })
        
    }
    
    func configureDatabase() {
        // TODO: configure database to sync messages
        
        ref = FIRDatabase.database().reference()
        
        _refHandle = ref.child("messages").observe(.childAdded ) { (snapChat : FIRDataSnapshot) in
            self.messages.append(snapChat)
            //self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count-1, section : 0)], with: .automatic )
            //self.scrollToBottomMessage()
            
        }
    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        
        storageRef = FIRStorage.storage().reference()
    }
    
    deinit {
        // need to remove observer or else it will continue after view not active-memory hog
        ref.child("messages").removeObserver(withHandle: _refHandle)
        
        FIRAuth.auth()?.removeStateDidChangeListener(_authHandle)
        
    }
    
    // MARK: Remote Config
    
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
                let friendlyMsgLength = self.remoteConfig ["friendly_msg_length"]
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
    
    // MARK: Sign In and Out
    
    
    func signedInStatus(isSignedIn: Bool) {
        
        signInButton.isHidden = isSignedIn
        signOutButton.isHidden = !isSignedIn
        playGameButton.isHidden = !isSignedIn
        
        if (isSignedIn) {
            
            configureDatabase()
            configureStorage()
            configureRemoteConfig()
            fetchConfig()
            print ("request cl location")
            
            //clLocManager.requestAlwaysAuthorization()

            //if CLLocationManager.authorizationStatus() == .notDetermined {
            //    clLocManager.requestWhenInUseAuthorization()
            //}
            // TODO: Set up app to send and receive messages when signed in
        }
    }
    
    func loginSession() {
        print ("login")
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }
    
    
    // TODO: create method that pushes message w/ photo to the firebase database
    
    
    // MARK: Alert
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func showLoginView(_ sender: AnyObject) {
        loginSession()
    }
    
    @IBAction func didTapAddPhoto(_ sender: AnyObject) {
        //returnCurrentBus()
        pickAPlace ()
        /*
         let picker = UIImagePickerController()
         picker.delegate = self
         picker.sourceType = .photoLibrary
         present(picker, animated: true, completion: nil)
         */
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        
        print ("signOut?")

        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("unable to sign out: \(error)")
        }
    }
    
    func locationManager(manager: CLLocationManager,
                         didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        // this is not being used..
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            returnCurrentBus()
        }
    }
    
    func pickAPlace () {
        
        // Create a place picker.
        //let window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = self
        
        let splitPaneViewController = SplitPaneViewController(rootViewController: rootViewController)
        
        // If we're on iOS 8 or above wrap the split pane controller in a inset controller to get the
        // map displaying behind our content on iPad devices.
        if #available(iOS 8.0, *) {
            let mapController = BackgroundMapViewController()
            rootViewController.mapViewController = mapController
            let insetController = InsetViewController(backgroundViewController: mapController,
                                                      contentViewController: splitPaneViewController)
            self.view.window?.rootViewController = insetController
        } else {
            self.view.window?.rootViewController = splitPaneViewController
        }
        
        //window.makeKeyAndVisible()
        
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePicker(config: config)
        
        // Present it fullscreen.
        placePicker.pickPlace { (place, error) in
            
            // Handle the selection if it was successful.
            if let place = place {
                // Create the next view controller we are going to display and present it.
                
                let nextScreen = PlaceDetailViewController(place: place)
                self.splitPaneViewController?.push(viewController: nextScreen, animated: false)
                self.mapViewController?.coordinate = place.coordinate
                print ( "coordinate \(place.coordinate)")
                self.gameLocationLable.text = place.name

            } else if error != nil {
                // In your own app you should handle this better, but for the demo we are just going to log
                // a message.
                NSLog("An error occurred while picking a place: \(error)")
            } else {
                NSLog("Looks like the place picker was canceled by the user")
            }
            
            // Release the reference to the place picker, we don't need it anymore and it can be freed.
            self.placePicker = nil
            
        }
        self.placePicker = placePicker

    }
    
    func returnCurrentBus ( ) {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        if (authorizationStatus == .authorizedWhenInUse) {
            locManager.startUpdatingLocation()
            
            let placesClient = GMSPlacesClient.shared()
            print ("return current bus")
            placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
                if let error = error {
                    print("Pick Place error: \(error.localizedDescription)")
                    return
                }
                
                if let placeLikelihoodList = placeLikelihoodList {
                    
                    self.gameLocationLable.text = placeLikelihoodList.likelihoods[0].place.name
                    
                    print ( placeLikelihoodList.likelihoods[0].place.name )
                    print ( placeLikelihoodList.likelihoods[0].likelihood )
                    print ( placeLikelihoodList.likelihoods[0].place.placeID )
                    
                    /*
                     for likelihood in placeLikelihoodList.likelihoods {
                     let place = likelihood.place
                     print("Current Place name \(place.name) at likelihood \(likelihood.likelihood)")
                     print("Current Place address \(place.formattedAddress)")
                     print("Current Place attributions \(place.attributions)")
                     print("Current PlaceID \(place.placeID)")
                     }
                     */
                }
            })
            
        } else if (authorizationStatus == CLAuthorizationStatus.denied ) {
            return
        } else {
            locManager.requestWhenInUseAuthorization()
            returnCurrentBus()
        }
        
    }
    
    
}




