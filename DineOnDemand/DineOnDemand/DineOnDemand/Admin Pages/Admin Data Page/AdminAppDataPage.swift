//
//  AdminAppDataPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/22/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AdminAppDataPage: UIViewController {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var adminAccountNameLabel: UILabel!
    @IBOutlet weak var currentDateLabel: UILabel!
    
    func getDate(){
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        self.currentDateLabel.text = "\(dateFormatter.string(from: date))"
    }
    @IBAction func signOutButtonTapped(_ sender: Any) {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            print("Sign out was successful!")
            UserDefaults().removeObject(forKey: "userData")
            self.performSegue(withIdentifier: "signOut", sender: self)
        } catch { }
    }
    func getAccountName(){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {return}
            
            let accountName = data["full_name"] as! String
            self.adminAccountNameLabel.text = "\(accountName)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDate()
        getAccountName()
    }
}
