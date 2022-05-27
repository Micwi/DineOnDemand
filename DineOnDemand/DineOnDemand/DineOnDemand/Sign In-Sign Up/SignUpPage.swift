//
//  SignUpPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/5/22.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SignUpPage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var fullNameTF: UITextField!
    @IBOutlet weak var emailAddressTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    @IBOutlet weak var yesNoSegCntrl: UISegmentedControl!
    @IBOutlet weak var employeeOrManagerSegCntrl: UISegmentedControl!
    @IBOutlet weak var restaurantCodeTF: UITextField!
    @IBOutlet weak var signUpButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        updateSignUpButtonState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Hides keyboard when you leave the view
        super.viewWillDisappear(true)
        self.view.endEditing(true)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func setupTextFields() {
        self.fullNameTF.delegate = self; self.emailAddressTF.delegate = self; self.passwordTF.delegate = self
        self.confirmPasswordTF.delegate = self; self.restaurantCodeTF.delegate = self
    }
    
    @IBAction func yesNoSegCntrlTapped(_ sender: Any) {
        updateSignUpButtonState()
        self.view.endEditing(true)
        let result = yesNoSegCntrl.titleForSegment(at: yesNoSegCntrl.selectedSegmentIndex)
        if result == "Yes" { restaurantCodeTF.isHidden = false; employeeOrManagerSegCntrl.isHidden = false }
        else if result == "No" { restaurantCodeTF.isHidden = true; employeeOrManagerSegCntrl.isHidden = true }
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        if (passwordTF.text != confirmPasswordTF.text) { passwordWarning() }
        else { registerCustomerAccount() }
    }
    
    func registerCustomerAccount() {
        self.signUpButton.isEnabled = false; self.signUpButton.alpha = 0.5; self.signUpButton.setTitle("Registering...", for: .normal)
        // Create user account (in accounts/users section)
        FirebaseAuth.Auth.auth().createUser(withEmail: emailAddressTF.text!, password: passwordTF.text!, completion: { result, error in
            guard error == nil else {
                print("An error occured while attempting to register this account...")
                self.signUpButton.isEnabled = true; self.signUpButton.alpha = 1; self.signUpButton.setTitle("Sign Up", for: .normal)
                self.alreadyRegisteredWarning()
                return
            }
            // Creates user data in database
            let signedInAccountID = result!.user.uid // Gets the UID of the customer account that was just created
            if self.yesNoSegCntrl.titleForSegment(at: self.yesNoSegCntrl.selectedSegmentIndex) == "Yes" {
                // Runs when the user said they work for a restaurant
                self.createNonCustomerAccountDataInDB(accountID: signedInAccountID)
                let selectedAccountType = self.employeeOrManagerSegCntrl.titleForSegment(at: self.employeeOrManagerSegCntrl.selectedSegmentIndex)
                if selectedAccountType == "Employee" {
                    self.pendingActivationWarning1()
                } else if selectedAccountType == "Manager" {
                    self.pendingActivationWarning2()
                }
            } else {
                // Runs when the user did not say they work for a restaurant
                self.createCustomerAccountDataInDB(accountID: signedInAccountID)
                self.createAddressDataInDatabase(accountID: signedInAccountID)
                self.createPaymentDataInDatabase(accountID: signedInAccountID)
                self.registrationCompleteAlert()
            }
            self.sendVerificationEmail()
        })
    }
    
    func sendVerificationEmail() { Auth.auth().currentUser?.sendEmailVerification { error in } }
    
    func alreadyRegisteredWarning() {
        let alertController = UIAlertController(title: NSLocalizedString("Already Registered",comment:""), message: NSLocalizedString("Your account has already been registered. Please return to the Sign In page and try again.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func passwordWarning() {
        let alertController = UIAlertController(title: NSLocalizedString("Password Warning",comment:""), message: NSLocalizedString("Passwords don't match. Please re-enter your password and try again.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func pendingActivationWarning1() {
        let alertController = UIAlertController(title: NSLocalizedString("Pending Activation",comment:""), message: NSLocalizedString("Your account registration has been submitted and is now pending activation from your manager. Once your manager approves of your account registration, your account will be activated and you will be able to sign in.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
            self.navigationController?.popViewController(animated: true)
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func pendingActivationWarning2() {
        let alertController = UIAlertController(title: NSLocalizedString("Pending Activation",comment:""), message: NSLocalizedString("Your account registration has been submitted and is now pending activation from an Admin. Once an Admin approves of your account registration, your account will be activated and you will be able to sign in.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
            self.navigationController?.popViewController(animated: true)
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func registrationCompleteAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Registration Complete",comment:""), message: NSLocalizedString("Registration successful! Please check your email inbox, confirm your account, and then sign in.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
            self.navigationController?.popViewController(animated: true)
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func createCustomerAccountDataInDB(accountID: String) {
        let encryptedPassword = try? EncryptionManager.encryptMessage(message: passwordTF.text!)
        self.database.collection("account").document("account_\(accountID)").setData([
            "account_id": accountID,
            "full_name": fullNameTF.text!,
            "email_address": emailAddressTF.text!,
            "password": encryptedPassword!,
            "account_type": "Customer",
            "account_status": "Activated",
            "amount_spent": 0,
            "gift_card_balance": 0,
            "last_reset_date": getSundaysDate(from: Date())
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func createNonCustomerAccountDataInDB(accountID: String) {
        var accountType = "TBD"; let encryptedPassword = try? EncryptionManager.encryptMessage(message: passwordTF.text!)
        let selectedAccountType = employeeOrManagerSegCntrl.titleForSegment(at: employeeOrManagerSegCntrl.selectedSegmentIndex)
        print("Selected Account Type: ", selectedAccountType!)
        if selectedAccountType == "Manager" { accountType = "Manager" }
        self.database.collection("account").document("account_\(accountID)").setData([
            "account_id": accountID,
            "full_name": fullNameTF.text!,
            "email_address": emailAddressTF.text!,
            "password": encryptedPassword!,
            "account_type": accountType,
            "account_status": "Not Activated",
            "restaurant_code": restaurantCodeTF.text!
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func createAddressDataInDatabase(accountID: String) {
        self.database.collection("account").document("account_\(accountID)").collection("delivery_address").document("default").setData([
            "street_address": "",
            "city": "No Address on Record",
            "state": "",
            "zip_code": "",
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func createPaymentDataInDatabase(accountID: String) {
        self.database.collection("account").document("account_\(accountID)").collection("payment_info").document("default").setData([
            "card_number": "",
            "expiration_date": "No Card on Record",
            "name_on_card": "",
            "security_code": "",
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func getSundaysDate(from sourceDate:Date) -> String {
        let calendar = NSCalendar(calendarIdentifier: .gregorian)!
        let source = sourceDate.components
        var components = DateComponents()
        components.weekOfYear = source.weekOfYear
        components.weekday = 1 // 1 = Sunday's date
        components.yearForWeekOfYear = source.yearForWeekOfYear
        let format = DateFormatter()
        format.dateFormat = "MM/dd/yyyy"
        format.string(from: calendar.date(from: components)!)
        return format.string(from: calendar.date(from: components)!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text!.count >= 38 && string != "" { return false }
        if textField.placeholder == "John Smith" {
            return dontAllowNumbers(string: string)
        }
        return true
    }
    
    func dontAllowNumbers(string: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[^A-Za-z ].*", options: [])
            if regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) != nil {
                return false
            }
        } catch {  }
        return true
    }
    
    
    
    // ** Validation Related Stuff **
    
    
    
    private var fullName: String { return self.fullNameTF.text ?? "" }
    private var email: String { return self.emailAddressTF.text ?? "" }
    private var password: String { return self.passwordTF.text ?? "" }
    private var confirmPassword: String { return self.confirmPasswordTF.text ?? "" }
    private var restaurantCode: String { return self.restaurantCodeTF.text ?? "" }
    
    private func updateSignUpButtonState() {
        var isValid = Bool(); let segCntrl = yesNoSegCntrl.titleForSegment(at: yesNoSegCntrl.selectedSegmentIndex)
        if (validateEmailAddress(emailAddress: emailAddressTF.text!) && validatePassword(password: passwordTF.text!) && validatePassword(password: confirmPasswordTF.text!)) {
            if (segCntrl == "No") {
                isValid = !self.fullName.isEmpty && !self.email.isEmpty && !self.password.isEmpty && !self.confirmPassword.isEmpty
            } else if (segCntrl == "Yes") {
                isValid = !self.fullName.isEmpty && !self.email.isEmpty && !self.password.isEmpty && !self.confirmPassword.isEmpty && !self.restaurantCode.isEmpty
            }
        }
        
        self.signUpButton.isEnabled = isValid
        self.signUpButton.alpha = isValid ? 1.0 : 0.5
    }
    
    @IBAction private func textFieldValueDidChange(_ sender: UITextField) {
        self.updateSignUpButtonState()
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
    
    // ** Moving Keyboard Down Code **
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - 120, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + 120, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }
    
}
