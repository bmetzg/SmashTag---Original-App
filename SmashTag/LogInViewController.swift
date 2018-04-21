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


class LogInViewController: UIViewController, CLLocationManagerDelegate {
   // removed NavigationControlerDelegate 6/8
    
    let smashPlayersModel = SmashTagDataSource.sharedInstance
    
    private var placePicker: GMSPlacePicker?
    var mapViewController: BackgroundMapViewController?
    
    var locManager: CLLocationManager!    
    
    // MARK: Outlets
    
    @IBOutlet weak var activityMonitorOutlet: UIActivityIndicatorView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var locateMeButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!

    @IBOutlet var dismissImageRecognizer: UITapGestureRecognizer!
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var gameLocationLable: UILabel!
    @IBOutlet weak var playGameButton: UIButton!

    @IBAction func locateMeAction(_ sender: Any) {
        
        func openLocationSettings(){
            let scheme:String = UIApplicationOpenSettingsURLString
            if let url = URL(string: scheme) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],
                                              completionHandler: {
                                                (success) in
                                                print("Open \(scheme): \(success)")
                    })
                } else {
                    let success = UIApplication.shared.openURL(url)
                    print("Open \(scheme): \(success)")
                }
            }
        }
        let manager = CLLocationManager()

        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse :
            print ("pickaplace")
            pickAPlace()
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .restricted, .denied:
            
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "Location Services need to be enabled to play Smash Tag!   Go to Settings/ SmashTag!/ Location  and set to Allow Location Access.",
                preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
                openLocationSettings()
            }
            alertController.addAction(openAction)
            self.present(alertController, animated: true, completion: nil)
        }


        /*
        let authorization CLLocationManager.authorizationStatus()
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse  || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorized {
            print ("pickaplace")
            pickAPlace()
        }
        else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            showAlert(title: "Location Services", message: "Location Services need to be enabled to play Smash Tag!   Go to Settings/ SmashTag!/ Location  and set to Allow Location Access.")
        }
        else {
            showAlert(title: "Location Services", message: "LCLLocationManager.authorizationStatus\(CLLocationManager.authorizationStatus())")
        }
         */
    
    }
    
    @IBAction func playGameAction(_ sender: Any) {
        
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
        
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }

        guard smashPlayersModel.gamePlayerLocation != "" else {
            showAlert(title: "Bar location", message: "You need to check into a bar location to start playing Smash Tag!")
            return
        }
        
        let gameView = storyboard!.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        //gameView.title = smashPlayersModel.playerName + "'s Game"

        present(gameView, animated: true, completion: nil)

        /*  Back Button
        let nav1 = UINavigationController()
        nav1.viewControllers = [self]
        self.view.window!.rootViewController = nav1
        self.view.window?.makeKeyAndVisible()
        
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        gameView.title = smashPlayersModel.playerName + "'s Game"
        
        if self.navigationController == nil {print("play game Controller nil")}
        self.navigationController?.show(gameView, sender: true )
        */
        
    }
    
    @IBAction func showLoginView(_ sender: AnyObject) {
        loginSession()
    }
    
    @IBAction func signOut(_ sender: UIButton) {
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
        
        if !smashPlayersModel.connectedToInternet {
            self.showAlert ( title: "Network Error", message: "User is not connected to the internet. Please check your network connection and try again")
            return
        }

        do {

            try FIRAuth.auth()?.signOut()

        } catch {
            showAlert(title: "Sign Out", message: "Unable to sign out \(error)")        }
    }
    
    func findLocationifPossible()
    {
        locManager = CLLocationManager()
        
        // For use in foreground
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locManager.delegate = self
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.requestAlwaysAuthorization()
            self.locationManager(manager: locManager, didChangeAuthorizationStatus: CLLocationManager.authorizationStatus())
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse{
                locManager.startUpdatingLocation()
                returnCurrentBus()
            }
            else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
                showAlert(title: "Location Services", message: "Location Services need to be enabled to play Smash Tag!   Go to Settings, SmashTag!, Location Services to enable.")
            }
        }
        else {
            showAlert(title: "Location Services", message: "Location Services need to be enabled to play Smash Tag!")
        }

    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case
        .authorized,
        .authorizedWhenInUse,
        .authorizedAlways:      locManager.startUpdatingLocation()
                                returnCurrentBus()
        default     :  break

        }
    }

    func updateScoreScreen() {
        
        var score : String = "Score:"
        var i : Int = 1
        
        if smashPlayersModel.playerScore == 0 {
            score = score + " 0"

        }
        else if smashPlayersModel.playerScore <= -1 {
            score = score + " Down "
            let thePlayerScore = smashPlayersModel.playerScore * -1
            while i <= thePlayerScore {
                score = score + " 🥛"
                i = i + 1
            }
            
        }
        else
        {
            let thePlayerScore = smashPlayersModel.playerScore
            while i <= thePlayerScore {
                score = score + " 🍺"
                i = i + 1
            }
        }
        scoreLabel.text = score
    }
    
    func endUserAgree() -> Bool {
        
        let AlertOnce = UserDefaults.standard
        if !AlertOnce.bool(forKey: "oneTimeAlert") {
        
            UserDefaults.standard.set("", forKey: "block")

            func someHandler(alert: UIAlertAction!) {
                AlertOnce.set(true , forKey: "oneTimeAlert")
                AlertOnce.synchronize()
                gameLogin()
            }
        
            let alert = UIAlertController()
            alert.title = "End User Agreement"
            alert.message = "SmashTag! App End User License Agreement \nThis End User License Agreement (“Agreement”) is between you and SmashTag! and governs use of this app made available through the Apple App Store. By installing the SmashTag!  App, you agree to be bound by this Agreement and understand that there is no tolerance for objectionable content. If you do not agree with the terms and conditions of this Agreement, you are not entitled to use the SmashTag! App.\n\n In order to ensure SmashTag! provides the best experience possible for everyone, we strongly enforce a no tolerance policy for objectionable content. If you see inappropriate content, please use the “Report as offensive” feature found under each post.\n1. Parties\nThis Agreement is between you and SmashTag! only, and not Apple, Inc. (“Apple”). Notwithstanding the foregoing, you acknowledge that Apple and its subsidiaries are third party beneficiaries of this Agreement and Apple has the right to enforce this Agreement against you. SmashTag!, not Apple, is solely responsible for the SmashTag! App and its content.\n2. Privacy\nSmashTag!  may collect and use information about your usage of the SmashTag!  App, including certain types of information from and about your device. SmashTag! may use this information, as long as it is in a form that does not personally identify you, to measure the use and performance of the SmashTag! App.\n3. Limited License\nSmashTag! grants you a limited, non-exclusive, non-transferable, revocable license to use the SmashTag! App for your personal, non-commercial purposes. You may only use the SmashTag! App on Apple devices that you own or control and as permitted by the App Store Terms of Service.\n4. Age Restrictions\nBy using the SmashTag! App, you represent and warrant that (a) you are 18 years of age or older and you agree to be bound by this Agreement; (b) if you are under 18 years of age, you have obtained verifiable consent from a parent or legal guardian; and (c) your use of the SmashTag! App does not violate any applicable law or regulation. Your access to the SmashTag! App may be terminated without warning if SmashTag! believes, in its sole discretion, that you are under the age of 18 years and have not obtained verifiable consent from a parent or legal guardian. If you are a parent or legal guardian and you provide your consent to your child’s use of the SmashTag! App, you agree to be bound by this Agreement in respect to your child’s use of the SmashTag! App.\n5. Objectionable Content Policy\nContent may not be submitted to SmashTag! ,who will moderate all content and ultimately decide whether or not to post a submission to the extent such content includes, is in conjunction with, or alongside any, Objectionable Content. Objectionable Content includes, but is not limited to: (i) sexually explicit materials; (ii) obscene, defamatory, libelous, slanderous, violent and/or unlawful content or profanity; (iii) content that infringes upon the rights of any third party, including copyright, trademark, privacy, publicity or other personal or proprietary right, or that is deceptive or fraudulent; (iv) content that promotes the use or sale of illegal or regulated substances, tobacco products, ammunition and/or firearms; and (v) gambling, including without limitation, any online casino, sports books, bingo or poker.\n6. Warranty\nSmashTag! disclaims all warranties about the SmashTag! App to the fullest extent permitted by law. To the extent any warranty exists under law that cannot be disclaimed, SmashTag!, not Apple, shall be solely responsible for such warranty.\n7. Maintenance and Support\nSmashTag! does provide minimal maintenance or support for it but not to the extent that any maintenance or support is required by applicable law, SmashTag!, not Apple, shall be obligated to furnish any such maintenance or support.\n8. Product Claims\nSmashTag!, not Apple, is responsible for addressing any claims by you relating to the SmashTag! App or use of it, including, but not limited to: (i) any product liability claim; (ii) any claim that the SmashTag! App fails to conform to any applicable legal or regulatory requirement; and (iii) any claim arising under consumer protection or similar legislation. Nothing in this Agreement shall be deemed an admission that you may have such claims.\n9. Third Party Intellectual Property Claims\nSmashTag! shall not be obligated to indemnify or defend you with respect to any third party claim arising out or relating to the SmashTag! App. To the extent SmashTag! is required to provide indemnification by applicable law, SmashTag!, not Apple, shall be solely responsible for the investigation, defense, settlement and discharge of any claim that the SmashTag! App or your use of it infringes any third party intellectual property right."
            
            
                alert.addAction(UIAlertAction(title: "I Agree", style: UIAlertActionStyle.default, handler: someHandler ))
                //alert.addAction(UIAlertAction(title: "Exit", style: UIAlertActionStyle.cancel, handler: someHandler))
                self.present(alert, animated: true)
                return false
            
        }
        else
        {
        return true
        }
    }
    
    func gameLogin() {
        
        smashPlayersModel.gamePlayerLocation = ""
        
        activityMonitorOutlet.startAnimating()
        
        signedInStatus(isSignedIn: false)
        
        configureAuth()
        findLocationifPossible ()
            
        let defaults = UserDefaults.standard
        
        if let myArray = (defaults.array( forKey: "block") as? [String]) {
            smashPlayersModel.blockUsers = myArray
        }
        
        smashPlayersModel.playerScore = defaults.integer(forKey: "score")
        print ("SCORE \(smashPlayersModel.playerScore)")
        updateScoreScreen()
        
        let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.smashPlayersModel.connectedToInternet = true
            } else {
                self.smashPlayersModel.connectedToInternet = false
            }
        })
        
        activityMonitorOutlet.stopAnimating()
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if endUserAgree() {
            gameLogin()
        }
        


    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super .viewDidAppear(animated)
        
        self.updateScoreScreen()


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
        
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {
        
        signInButton.isHidden = isSignedIn
        signOutButton.isHidden = !isSignedIn
        playGameButton.isHidden = !isSignedIn
        
        return
    }
    
    func configureAuth() {
        // Listens for changes in the authorization state
        
        let provider:[FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        smashPlayersModel._authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth : FIRAuth, user : FIRUser? ) in
            print ("signed in?")
            
        if let activeUser = user {
                if self.smashPlayersModel.user != activeUser {
                        print ("signed in")
                        
                        self.smashPlayersModel.user = activeUser
                        self.signedInStatus(isSignedIn: true)
                        let name = user!.email!.components(separatedBy: "@")[0]
                        self.smashPlayersModel.playerName = name
                        // name & location & gamepartner & winlost
                        //self.findLocationifPossible()
                        self.smashPlayersModel.setUpAccessToFireBase()
                }
                return
        }
            
        print ("not signed in")
        self.signedInStatus(isSignedIn: false)
        //self.loginSession()
            
        //self.smashPlayersModel.setUpAccessToFireBase()
    
        let defaults = UserDefaults.standard
        self.smashPlayersModel.playerScore = defaults.integer(forKey: "score")
        print ("SCORE \(self.smashPlayersModel.playerScore)")

        })
    }
    
    deinit
    {
        FIRAuth.auth()?.removeStateDidChangeListener(smashPlayersModel._authHandle)
        print ( "login remove auth listener")
        
    }
    
    func loginSession() {
        print ("login")
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }
    
    // MARK: Alert
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
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
        
        self.view.window?.makeKeyAndVisible()
        
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
                self.smashPlayersModel.gamePlayerLocation = place.placeID
                
            } else if error != nil {
                // In your own app you should handle this better, but for the demo we are just going to log
                // a message.
                self.showAlert ( title: "Location Error", message: "User is not connected to the internet. Please check your network connection and try again")
                
                NSLog("An error occurred while picking a place: \(String(describing: error))")
                return
            } else {
                NSLog("Looks like the place picker was canceled by the user")
            }
            
            // Release the reference to the place picker, we don't need it anymore and it can be freed.
            self.placePicker = nil
            
        }
        self.placePicker = placePicker

    }
    
    func returnCurrentBus ( ) {
        
        let placesClient = GMSPlacesClient.shared()
        print ("return current bus")
        
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                
                    self.showAlert ( title: "Location Error", message: "User is not connected to the internet. Please check your network connection and try again")

                    print("Pick Place error: \(error.localizedDescription)")
                
                    return
            }
                
        if let placeLikelihoodList = placeLikelihoodList {
                    
            self.gameLocationLable.text = placeLikelihoodList.likelihoods[0].place.name
                    
            print ( placeLikelihoodList.likelihoods[0].place.name )
            print ( placeLikelihoodList.likelihoods[0].likelihood )
            print ( placeLikelihoodList.likelihoods[0].place.placeID )
            
            self.smashPlayersModel.gamePlayerLocation = placeLikelihoodList.likelihoods[0].place.placeID
            
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

    }
}




