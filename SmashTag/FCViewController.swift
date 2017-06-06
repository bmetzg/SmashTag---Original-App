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

// MARK: - FCViewController

class FCViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: Properties
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 1000
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
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var imageMessage: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var messagesTable: UITableView!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet var dismissImageRecognizer: UITapGestureRecognizer!
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        //self.signedInStatus(isSignedIn: true)
        // this allowed users to sign in anonymously
        //replaceing this with authentication - bm
        
        configureAuth()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Config
    
    func configureAuth() {
        // Listens for changes in the authorization state
        
        let provider:[FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        //
        
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth : FIRAuth, user : FIRUser? ) in
            
            self.messages.removeAll()
            self.messagesTable.reloadData()
            
            if let activeUser = user {
                if self.user != activeUser {
                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                }
                else {
                self.signedInStatus(isSignedIn: false)
                    self.loginSession()
                }
            }
        })
        
    }
    
    func configureDatabase() {
        // TODO: configure database to sync messages
        
        ref = FIRDatabase.database().reference()
        
        _refHandle = ref.child("messages").observe(.childAdded ) { (snapChat : FIRDataSnapshot) in
            self.messages.append(snapChat)
            self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count-1, section : 0)], with: .automatic )
            self.scrollToBottomMessage()
            
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
        messagesTable.isHidden = !isSignedIn
        messageTextField.isHidden = !isSignedIn
        sendButton.isHidden = !isSignedIn
        imageMessage.isHidden = !isSignedIn
        
        if (isSignedIn) {
            
            // remove background blur (will use when showing image messages)
            messagesTable.rowHeight = UITableViewAutomaticDimension
            messagesTable.estimatedRowHeight = 122.0
            backgroundBlur.effect = nil
            messageTextField.delegate = self
            
            configureDatabase()
            configureStorage()
            configureRemoteConfig()
            fetchConfig()
            
            // TODO: Set up app to send and receive messages when signed in
        }
    }
    
    func loginSession() {
        print ("login")
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }
    
    // MARK: Send Message
    
    func sendMessage(data: [String:String]) {
        // TODO: create method that pushes message to the firebase database
        
        var mdata = data
        // add a key to the data
        mdata[Constants.MessageFields.name] = displayName
        
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
    
    // MARK: Scroll Messages
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: messagesTable.numberOfRows(inSection: 0) - 1, section: 0)
        messagesTable.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func showLoginView(_ sender: AnyObject) {
        loginSession()
    }
    
    @IBAction func didTapAddPhoto(_ sender: AnyObject) {
        returnCurrentBus()
        pickAPlace ()
        /*
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
 */
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("unable to sign out: \(error)")
        }
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        let _ = textFieldShouldReturn(messageTextField)
        messageTextField.text = ""
        
    }
    
    @IBAction func dismissImageDisplay(_ sender: AnyObject) {
        // if touch detected when image is displayed
        if imageDisplay.alpha == 1.0 {
            UIView.animate(withDuration: 0.25) {
                self.backgroundBlur.effect = nil
                self.imageDisplay.alpha = 0.0
            }
            dismissImageRecognizer.isEnabled = false
            messageTextField.isEnabled = true
        }
    }
    
    @IBAction func tappedView(_ sender: AnyObject) {
        resignTextfield()
    }
    
    func pickAPlace () {
        // Create a place picker.
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePicker(config: config)
        
        // Present it fullscreen.
        placePicker.pickPlace { (place, error) in
            
            // Handle the selection if it was successful.
            if let place = place {
                // Create the next view controller we are going to display and present it.
                let nextScreen = PlaceDetailViewController(place: place)
                self.splitPaneViewController?.push(viewController: nextScreen, animated: false)
                //self.mapViewController?.coordinate = place.coordinate
            } else if error != nil {
                // In your own app you should handle this better, but for the demo we are just going to log
                // a message.
                NSLog("An error occurred while picking a place: \(error)")
            } else {
                NSLog("Looks like the place picker was canceled by the user")
            }
            
            // Release the reference to the place picker, we don't need it anymore and it can be freed.
            //self.placePicker = nil

        }
    }
        
    func returnCurrentBus ( ) {
        
        let locationManager = CLLocationManager()
        // For getting the user permission to use location service when the app is running
        locationManager.requestWhenInUseAuthorization()
        // For getting the user permission to use location service always
        //locationManager.requestAlwaysAuthorization()
        
        let placesClient = GMSPlacesClient.shared()
        print ("return current bus")
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                for likelihood in placeLikelihoodList.likelihoods {
                    let place = likelihood.place
                    print("Current Place name \(place.name) at likelihood \(likelihood.likelihood)")
                    print("Current Place address \(place.formattedAddress)")
                    print("Current Place attributions \(place.attributions)")
                    print("Current PlaceID \(place.placeID)")
                }
            }
        })
        
    }


    
    

}


// MARK: - FCViewController: UITableViewDelegate, UITableViewDataSource

extension FCViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue cell
        var cell: UITableViewCell! = messagesTable.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        
        let messageSnapChat : FIRDataSnapshot! = messages[indexPath.row]
        let message = messageSnapChat.value as! [String:String]
        
        let name = message [Constants.MessageFields.name] ?? "[username]"
        
        if let imageURL = message[Constants.MessageFields.imageUrl] {
            
            cell.textLabel?.text = "sent by:\(name)"
            //download and display the image
            FIRStorage.storage().reference(  forURL : imageURL ).data(withMaxSize: INT64_MAX ){ (data, error) in
                guard error == nil else {
                    print ( "error returning image \(error)")
                    return
                }
                
                let messageimage = UIImage.init(data: data!, scale : 50 )
                if cell == tableView.cellForRow(at: indexPath) {
                    DispatchQueue.main.async {
                        cell.imageView?.image = messageimage
                        cell.setNeedsLayout()
                        }
                }
            }
        }
        else {
            let text = message [Constants.MessageFields.text] ?? "[message]"
            cell.textLabel?.text = name + " : " + text
            cell.imageView?.image = placeholderImage
        }
        
        return cell!
        // TODO: update cell to display message data
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: if message contains an image, then display the image

        // skip if keyboard is shown
        guard !messageTextField.isFirstResponder else { return }
        
        // unpack message from firebase data snapshot
        let messageSnapshot: FIRDataSnapshot! = messages[(indexPath as NSIndexPath).row]
        let message = messageSnapshot.value as! [String: String]
        
        // if tapped row with image message, then display image - as it is text - do nothing
        if let imageUrl = message[Constants.MessageFields.imageUrl] {

        if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {
                showImageDisplay(cachedImage)
        } else {
            FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX){ (data, error) in
                guard error == nil else {
                    print("Error downloading: \(error!)")
                    return
                }
            self.showImageDisplay(UIImage.init(data: data!)!)
            }
        }
        }
    }
    // MARK: Show Image Display
    
    func showImageDisplay(_ image: UIImage) {
        dismissImageRecognizer.isEnabled = true
        dismissKeyboardRecognizer.isEnabled = false
        messageTextField.isEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.imageDisplay.alpha = 1.0
            self.imageDisplay.image = image
        }
    }
    
    // MARK: Show Image Display
    
    func showImageDisplay(image: UIImage) {
        dismissImageRecognizer.isEnabled = true
        dismissKeyboardRecognizer.isEnabled = false
        messageTextField.isEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.imageDisplay.alpha = 1.0
            self.imageDisplay.image = image
        }
    }
}

// MARK: - FCViewController: UIImagePickerControllerDelegate

extension FCViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        // constant to hold the information about the photo
        if let photo = info[UIImagePickerControllerOriginalImage] as? UIImage, let photoData = UIImageJPEGRepresentation(photo, 0.8) {
            // call function to upload photo message
            sendPhotoMessage( photoData: photoData )
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FCViewController: UITextFieldDelegate

extension FCViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // set the maximum length of the message
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= msglength.intValue
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.text!.isEmpty {
            let data = [Constants.MessageFields.text: textField.text! as String]
            sendMessage(data: data)
            textField.resignFirstResponder()
        }
        return true
    }
    
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
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        dismissKeyboardRecognizer.isEnabled = true
        scrollToBottomMessage()
    }
    
    func keyboardDidHide(_ notification: Notification) {
        dismissKeyboardRecognizer.isEnabled = false
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        return ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
    }
    
    func resignTextfield() {
        if messageTextField.isFirstResponder {
            messageTextField.resignFirstResponder()
        }
    }
}

// MARK: - FCViewController (Notifications)

extension FCViewController {
    
    func subscribeToKeyboardNotifications() {
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    func subscribeToNotification(_ name: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

