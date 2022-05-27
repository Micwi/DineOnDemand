//
//  viewAccountInfoPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/22/22.
//

import Firebase
import FirebaseFirestore
import FirebaseAuth
import UIKit


class viewAccountInfoPage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var fullNameTF: UITextField!
    @IBOutlet weak var accountIDTF: UITextField!
    @IBOutlet weak var emailAddressTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        getAccountInfoFromDB()
    }
    
    func getAccountInfoFromDB(){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {return}
            
            let accountName = data["full_name"] as! String
            let emailAddress = data["email_address"] as! String
            let password = data["password"] as! String
            
            self.fullNameTF.text = "\(accountName)"
            self.accountIDTF.text = "\(userID)"
            self.emailAddressTF.text = "\(emailAddress)"
            self.passwordTF.text = "\(password)"
        }
    }
    
    @IBAction func changePasswordButtonTapped(_ sender: Any) {
        changePasswordPopup()
    }
    func changePasswordPopup(){
        let alertController = UIAlertController(title: "Update Password", message: "Updating this password will replace your old password!", preferredStyle: .alert)
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Old Password" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "New Password" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Confirm New Password" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { _ in
            if alertController.textFields![0].text == "" || alertController.textFields![1].text == "" || alertController.textFields![2].text == ""{
                self.textFieldsIncompleteAlert()
            }else if(alertController.textFields![1].text == alertController.textFields![2].text ){
                if(alertController.textFields![0].text == self.passwordTF.text!){ self.changePassword(textfields: alertController.textFields!)}
                else{self.oldPasswordIncorrectAlert()}
            }else{self.passwordsIncorrectAlert()}
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func changePassword(textfields: [UITextField]){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let encryptedPassword = try? EncryptionManager.encryptMessage(message: textfields[1].text!)
        self.database.collection("account").document("account_\(userID)").setData([
            "password": encryptedPassword!
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    func textFieldsIncompleteAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "Could not be added. One or more fields were left empty or incomplete. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func passwordsIncorrectAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The passwords you entered do not match!", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    func oldPasswordIncorrectAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The old password you entered does not match the current password!", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        accountIDTF.isSecureTextEntry = false
    }
    
    @IBAction func eyeButtonLetGo(_ sender: Any) {
        accountIDTF.isSecureTextEntry = true
    }
    
}
