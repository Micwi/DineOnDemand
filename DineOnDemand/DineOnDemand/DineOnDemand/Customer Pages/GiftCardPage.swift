//
//  GiftCardPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/12/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class GiftCardPage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var giftCardCodeTF: UITextField!
    @IBOutlet weak var giftCardValueTF: UITextField!
    @IBOutlet weak var newCodeTF: UITextField!
    @IBOutlet weak var redeemButton: UIButton!
    @IBOutlet weak var paymentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        getLast4CardDigits()
    }
    
    func getLast4CardDigits() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = database.collection("account").document("account_\(userID)").collection("payment_info").document("default")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            var cardNumber = data["card_number"] as! String
            if cardNumber != "" {
                cardNumber = try! EncryptionManager.decryptMessage(encryptedMessage: cardNumber)
                self.paymentButton.setTitle("Pay now with *\(cardNumber.suffix(4))", for: .normal)
            } else {
                self.paymentButton.setTitle("Add Payment Method", for: .normal)
            }
            // Check card expiration date
            var expirationDate = data["expiration_date"] as! String
            if expirationDate != "No Card on Record" {
                expirationDate = try! EncryptionManager.decryptMessage(encryptedMessage: expirationDate)
                self.checkExpirationDate(expirationDate: expirationDate)
            }
        }
    }
    
    func checkExpirationDate(expirationDate: String) {
        // Validate the Expiration Date
        var dateComponent = DateComponents(); dateComponent.month = 1
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: Date())
        let currentMonthPlus1 = Calendar.current.component(.month, from: futureDate!)
        let year = getYear()
        
        let monthExp = Int(expirationDate.prefix(2))!; let yearExp = Int(expirationDate.suffix(2))!
        if yearExp == year { // if the year is 2022, we need to check the month to see if it's before the current month plus 1
            if monthExp <= currentMonthPlus1 {
                self.cardNeedsUpdateAlert()
                self.paymentButton.setTitle("Update Card", for: .normal)
            }
        } else if yearExp < year { // if the year is before 2022, it's expired
            self.cardNeedsUpdateAlert()
            self.paymentButton.setTitle("Update Card", for: .normal)
        }
    }
    
    func cardNeedsUpdateAlert() {
        let alertController = UIAlertController(title: "Card Expired/Expiring", message: "The card we have on record for your account is expired or is expiring very soon. Please enter a new card that has an expiration date that is at least two months after the current date.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Replace Card", style: .default) { _ in
            self.addPaymentMethodAlert()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func addPaymentMethodAlert() {
        let alertController = UIAlertController(title: "Modify Payment Info", message: "The payment info you enter here will replace any current payment info on file.", preferredStyle: .alert)
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Card Number" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Expiration Date" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Security Code" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Name on Card" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { _ in
            if alertController.textFields![0].text == "" || alertController.textFields![1].text == "" || alertController.textFields![2].text == "" || alertController.textFields![3].text == "" {
                self.textFieldsIncompleteAlert()
            } else if alertController.textFields![0].text!.count != 19 || alertController.textFields![1].text!.count != 5 || alertController.textFields![2].text!.count < 3 {
                self.textFieldsIncompleteAlert()
            } else {
                self.validateExpirationDateTextField(textFieldsInAlert: alertController.textFields!)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func validateExpirationDateTextField(textFieldsInAlert: [UITextField]) {
        // Validate the Expiration Date
        var dateComponent = DateComponents(); dateComponent.month = 1
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: Date())
        let currentMonthPlus1 = Calendar.current.component(.month, from: futureDate!)
        let year = getYear()
        
        if validate(userEntry: textFieldsInAlert[1].text!, regEx: "(0[1-9]|10|11|12)/[0-9]{2}$") {
            let monthExp = Int(textFieldsInAlert[1].text!.prefix(2))!; let yearExp = Int(textFieldsInAlert[1].text!.suffix(2))!
            if yearExp == year { // if the year is 2022, we need to check the month to see if it's before the current month plus 1
                if monthExp <= currentMonthPlus1 {
                    self.expiredCardAlert()
                } else { // Card expiration month is at least two months after the current month. Good to go
                    self.modifyPaymentInfo(textFieldsInAlert: textFieldsInAlert)
                    self.paymentButton.isEnabled = true
                }
            } else if yearExp > year { // if the year is past 2022, it's not expired and is good to go
                self.modifyPaymentInfo(textFieldsInAlert: textFieldsInAlert)
                self.paymentButton.isEnabled = true
            } else if yearExp < year { // if the year is before 2022, it's expired
                self.expiredCardAlert()
            }
        } else {
            self.invalidExpirationDateAlert()
        }
    }
    
    func modifyPaymentInfo(textFieldsInAlert: [UITextField]) {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let encryptedCardNumber = try? EncryptionManager.encryptMessage(message: textFieldsInAlert[0].text!)
        let encryptedExpDate = try? EncryptionManager.encryptMessage(message: textFieldsInAlert[1].text!)
        let encryptedSecurityCode = try? EncryptionManager.encryptMessage(message: textFieldsInAlert[2].text!)
        let encryptedNameOnCard = try? EncryptionManager.encryptMessage(message: textFieldsInAlert[3].text!)
        self.database.collection("account").document("account_\(userID)").collection("payment_info").document("default").setData([
            "card_number": encryptedCardNumber!,
            "expiration_date": encryptedExpDate!,
            "security_code": encryptedSecurityCode!,
            "name_on_card": encryptedNameOnCard!,
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
        self.getLast4CardDigits()
    }
    
    func textFieldsIncompleteAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "Could not be added. One or more fields were left empty or incomplete. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.addPaymentMethodAlert()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidExpirationDateAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The expiration date you entered is invalid. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.addPaymentMethodAlert()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func expiredCardAlert() {
        let alertController = UIAlertController(title: "Card Expired/Expiring", message: "The card you entered is expired or is expiring very soon. Please enter a new card that has an expiration date that is at least two months after the current date.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.addPaymentMethodAlert()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func getYear() -> Int {
        let year = Int("\(Calendar.current.component(.year, from: Date()))".suffix(2))!
        return year
    }
    
    func validate(userEntry: String, regEx: String) -> Bool {
        let regEx = regEx
        let trimmedString = userEntry.trimmingCharacters(in: .whitespaces)
        let validateEntry = NSPredicate(format:"SELF MATCHES %@", regEx)
        let isValid = validateEntry.evaluate(with: trimmedString)
        return isValid
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.tag == 3) { return false }
        if (textField.tag == 1 || textField.tag == 2) && string == " " { return false } // Block spaces from going through
        if ((textField.text?.count == 4 || textField.text?.count == 9 || textField.text?.count == 14) && string != "") && (textField.tag == 1) {
            textField.text! += "-"
        } else if (textField.text!.count >= 19 && string != "" && (textField.tag == 1)) {
            return false
        }
        
        if textField.placeholder == "Card Number" {
            if textField.text!.count >= 19 && string != "" {
                return false
            } else if ((textField.text?.count == 4 || textField.text?.count == 9 || textField.text?.count == 14) && string != "") {
                textField.text! += " "
            }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Expiration Date" {
            if textField.text!.count >= 5 && string != "" { return false }
            else if (textField.text?.count == 2) && string != "" { textField.text! += "/" }
            else if (textField.text?.count == 0) && string != "1" && string != "0" && string != "" { textField.text! += "0" }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Security Code" {
            if textField.text!.count >= 4 && string != "" { return false }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Name on Card" {
            return dontAllowNumbers(string: string)
        }
        return true
    }
    
    func onlyAllowNumbers(string: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[^0-9].*", options: [])
            if regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) != nil {
                return false
            }
        } catch {  }
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
    
    
    // ** REDEEM GIFT CARD CODE
    
    
    func setupTextFields() {
        giftCardCodeTF.delegate = self
        giftCardValueTF.delegate = self
        newCodeTF.delegate = self
    }
    
    @IBAction func redeemButtonTapped(_ sender: Any) {
        let docRef = self.database.collection("gift_card").document("gift_card_\(giftCardCodeTF.text!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                self.codeDoesntExistAlert()
                return
            }
            if data["was_redeemed"] as! String == "false" {
                let giftCardValue = data["initial_value"] as! Int
                self.codeRedeemedAlert(giftCardValue: giftCardValue)
                self.setWasRedeemedToTrue()
                self.addGiftCardToAccount(giftCardValue: giftCardValue)
            } else if data["was_redeemed"] as! String == "true" {
                self.codeAlreadyRedeemedAlert()
            }
        }
    }
    
    func setWasRedeemedToTrue() {
        self.database.collection("gift_card").document("gift_card_\(giftCardCodeTF.text!)").setData([
            "was_redeemed": "true",
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func addGiftCardToAccount(giftCardValue: Int) {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let currentGiftCardBalance = data["gift_card_balance"] as! Int
            self.database.collection("account").document("account_\(userID)").setData([
                "gift_card_balance": currentGiftCardBalance + giftCardValue,
            ], merge: true) { err in
                if let err = err { print("Error writing document: \(err)")
                } else { print("Document successfully written!") }
            }
        }
    }
    
    func codeDoesntExistAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Try Again",comment:""), message: NSLocalizedString("The code you entered does not exist. Please try again.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func codeAlreadyRedeemedAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Try Again",comment:""), message: NSLocalizedString("The code you entered has already been redeemed. Please try again.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func codeRedeemedAlert(giftCardValue: Int) {
        let alertController = UIAlertController(title: NSLocalizedString("Gift Card Redeemed Successfully",comment:""), message: NSLocalizedString("A gift card value of $\(giftCardValue) has been applied to your account!", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler:  { (pAlert) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // ** PURCHASE GIFT CARD
    
    
    @IBAction func paymentButtonTapped(_ sender: Any) {
        if self.paymentButton.titleLabel!.text == "Add Payment Method" {
            self.addPaymentMethodAlert()
        } else if self.paymentButton.titleLabel!.text == "Update Card" {
            self.addPaymentMethodAlert()
        } else {
            if giftCardValueTF.text!.trimmingCharacters(in: .whitespaces).isEmpty {
                // Ran when the text field is empty
                noValueEnteredAlert()
            } else {
                // Ran when the text field is not empty
                purchaseConfirmAlert()
            }
        }
    }
    
    func createGiftCard() {
        // Generates a completely random gift card code
        var fullGiftCardNumber = ""
        for i in 1...4 {
            let chunkLength = 4
            let possibleCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
            let chunkOfCode = String((0..<chunkLength).compactMap { _ in possibleCharacters.randomElement() })
            fullGiftCardNumber += chunkOfCode
            if i != 4 { fullGiftCardNumber += "-" }
        }
        
        // Checks to see if the code we just generated is already in the database
        let docRef = self.database.collection("gift_card").document("gift_card_\(fullGiftCardNumber)")
        docRef.getDocument { snapshot, error in
            guard let _ = snapshot?.data(), error == nil else {
                print("Code is ready to go")
                // Adds the gift card to the database
                self.database.collection("gift_card").document("gift_card_\(fullGiftCardNumber)").setData([
                    "code": fullGiftCardNumber,
                    "initial_value": Int(self.giftCardValueTF.text!)!,
                    "was_redeemed": "false",
                ]) { err in
                    if let err = err { print("Error writing document: \(err)")
                    } else { print("Document successfully written!") }
                }
                self.newCodeTF.isEnabled = true
                self.newCodeTF.text = fullGiftCardNumber
                self.purchaseSuccessAlert()
                return
            }
            // Generates another code if the code that was just generated already exists!
            self.createGiftCard()
        }
    }
    
    func noValueEnteredAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Enter Value",comment:""), message: NSLocalizedString("You must enter a value before attempting to purchase a gift card.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func purchaseConfirmAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Purchase Gift Card",comment:""), message: NSLocalizedString("Are you sure that you want to purchase a gift card in the amount of $\(giftCardValueTF.text!)?", comment: ""), preferredStyle: .actionSheet)
        let defaultAction2 = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler:  { (pAlert) in })
        let defaultAction = UIAlertAction(title: NSLocalizedString("Purchase", comment: ""), style: .default, handler:  { (pAlert) in
            self.createGiftCard()
        })
        alertController.addAction(defaultAction)
        alertController.addAction(defaultAction2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func purchaseSuccessAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Purchase Gift Card",comment:""), message: NSLocalizedString("Your gift card in the amount of $\(giftCardValueTF.text!) has been purchased successfully! Please save the gift card code that is now on this page and send it to someone as a gift or keep it for yourself.", comment: ""), preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 3 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - 125, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 3 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + 125, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }
    
}
