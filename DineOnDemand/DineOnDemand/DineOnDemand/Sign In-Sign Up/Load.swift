//
//  Load.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/6/22.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import RNCryptor

class Load: UIViewController {
    
    private let database = Firestore.firestore()
    
    static var empRestaurantCode = String()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if UserDefaults().dictionary(forKey: "userData") == nil {
            // Ran when no user was previously signed in
            self.performSegue(withIdentifier: "GoToSignInNav", sender: self)
        } else {
            // Ran when a user has previously signed in
            autoSignIn()
        }
    }
    
    func autoSignIn() {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")! // Get data from previous sign in and try to sign in using the email and password from it
        // Attempts to sign the user in
        let decryptedPassword = try? EncryptionManager.decryptMessage(encryptedMessage: userData["password"] as! String)
        FirebaseAuth.Auth.auth().signIn(withEmail: userData["email_address"] as! String, password: decryptedPassword!) { result, error in guard error == nil else {
                print("An error occured while attempting to sign in...")
                self.performSegue(withIdentifier: "GoToSignInNav", sender: self)
                return
            }
            var accountStatus = String()
            let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
            
            let docRef = self.database.collection("account").document("account_\(userID)")
            docRef.getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    return
                }
                accountStatus = data["account_status"] as! String
                let accountType = data["account_type"] as! String
                if accountStatus == "Activated" {
                    UserDefaults().setValue(data, forKey: "userData")
                    if accountType != "Customer" && accountType != "Admin" { Load.empRestaurantCode = data["restaurant_code"] as! String }
                    self.performSegue(withIdentifier: "GoTo\(accountType)HomePage", sender: self)
                } else if accountStatus == "Not Activated" {
                    do { try FirebaseAuth.Auth.auth().signOut(); print("Sign out was successful!") } catch { }
                }
            }
        }
    }
    
}
