//
//  SignInPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/4/22.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SignInPage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var emailAddressTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var signInButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        updateSignInButtonState()
    }
    
    func setupTextFields() { self.emailAddressTF.delegate = self; self.passwordTF.delegate = self }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
        signIn()
    }
    
    func signIn() {
        FirebaseAuth.Auth.auth().signIn(withEmail: emailAddressTF.text!, password: passwordTF.text!) { result, error in guard error == nil else {
                print("An error occured while attempting to sign in...")
                self.incorrectSignInInfoWarning()
                return
            }
            
            var accountStatus = String()
            let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
            
            let docRef = self.database.collection("account").document("account_\(userID)")
            docRef.getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    self.rejectedAccountWarning()
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
                    if accountType == "TBD" { self.accountNotActivatedWarning1() }
                    else if accountType == "Manager" { self.accountNotActivatedWarning2() }
                }
            }
        }
    }
    
    func deleteRejectedAccount() {
        let user = Auth.auth().currentUser
        user?.delete { error in
          if let error = error {
              print(error)
          }
        }
    }
    
    @IBAction func resetPasswordButtonTapped(_ sender: Any) {
        if !emailAddressTF.text!.isEmpty {
            Auth.auth().sendPasswordReset(withEmail: emailAddressTF.text!) { error in }
            resetPasswordLinkSent()
        }
    }
    
    func incorrectSignInInfoWarning() {
        let alertController = UIAlertController(title: NSLocalizedString("Incorrect Credentials",comment:""), message: NSLocalizedString("Email and/or password is incorrect. Please enter a valid email and password that was previously registered with DineOnDemand and try again.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func accountNotActivatedWarning1(){
        let alertController = UIAlertController(title: NSLocalizedString("Account Not Activated",comment:""), message: NSLocalizedString("Your account is still pending approval of activation from your manager. Please contact your manager and try again later.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func accountNotActivatedWarning2(){
        let alertController = UIAlertController(title: NSLocalizedString("Account Not Activated",comment:""), message: NSLocalizedString("Your account is still pending approval of activation from an admin. Please contact an admin and try again later.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func rejectedAccountWarning() {
        let alertController = UIAlertController(title: NSLocalizedString("Your Account Has Been Rejected",comment:""), message: NSLocalizedString("This account has been rejected by a restaurant manager. It will now be deleted. Please contact the restaurant manager if you believe this was done in error.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.deleteRejectedAccount()
        }
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func resetPasswordLinkSent(){
        let alertController = UIAlertController(title: NSLocalizedString("Reset Password",comment:""), message: NSLocalizedString("If an account exists under the email address entered above, a password reset link has been sent. Please check your inbox.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // Setting the character limit in text fields to 38
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 38
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    
    
    // ** Validation Related Stuff **
    
    
    
    private var email: String {
        return self.emailAddressTF.text ?? ""
    }
    
    private var password: String {
        return self.passwordTF.text ?? ""
    }
    
    private func updateSignInButtonState() {
        var isValid = Bool()
        if (validateEmailAddress(emailAddress: emailAddressTF.text!) && validatePassword(password: passwordTF.text!)) {
            isValid = !self.email.isEmpty && !self.password.isEmpty
        }
        
        self.signInButton.isEnabled = isValid
        self.signInButton.alpha = isValid ? 1.0 : 0.5
    }
    
    @IBAction private func textFieldValueDidChange(_ sender: UITextField) {
        self.updateSignInButtonState()
    }
    
    func validateEmailAddress(emailAddress: String) -> Bool { return validate(userEntry: emailAddress, regEx: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}") }
    
    // Minimum of eight characters including at least 1 letter and 1 number
    func validatePassword(password: String) -> Bool { return validate(userEntry: password, regEx: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$") }
    
    func validate(userEntry: String, regEx: String) -> Bool {
        let regEx = regEx
        let trimmedString = userEntry.trimmingCharacters(in: .whitespaces)
        let validateEntry = NSPredicate(format:"SELF MATCHES %@", regEx)
        let isValid = validateEntry.evaluate(with: trimmedString)
        return isValid
    }
    
}
