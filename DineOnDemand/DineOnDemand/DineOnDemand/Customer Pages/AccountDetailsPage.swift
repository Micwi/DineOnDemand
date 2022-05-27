//
//  AccountDetailsPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/10/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class AccountDetailsPage: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var table: UITableView!
    
    var sectionsArray = [Section(), Section(), Section(), Section()]
    var checkForData = Timer()
    
    struct Section {
        var sectionName: String!
        var sectionRow: [String]!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTableData()
    }
    
    func refreshTableData() {
        getGeneralData()
        getDeliveryAddressData()
        getPaymentInfoData()
        self.checkForData = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(getQueryData), userInfo: nil, repeats: false)
    }
    
    @objc func getQueryData() {
        if sectionsArray[3].sectionRow != nil {
            table.reloadData()
            self.checkForData.invalidate()
        }
    }
    
    func getGeneralData() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = database.collection("account").document("account_\(userID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            self.sectionsArray[0] = Section(sectionName: "Full Name", sectionRow: [data["full_name"] as! String])
            self.sectionsArray[1] = Section(sectionName: "Email Address", sectionRow: [data["email_address"] as! String])
            print("Got general data")
        }
    }
    
    func getDeliveryAddressData() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = database.collection("account").document("account_\(userID)").collection("delivery_address").document("default")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let streetAddress = data["street_address"] as! String
            let city = data["city"] as! String
            let state = data["state"] as! String
            let zipCode = data["zip_code"] as! String
            self.sectionsArray[2] = Section(sectionName: "Delivery Address", sectionRow: [streetAddress, city, state, zipCode])
            print("Go delivery data")
        }
    }
    
    func getPaymentInfoData() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = database.collection("account").document("account_\(userID)").collection("payment_info").document("default")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            
            var cardNumber = data["card_number"] as! String
            var expirationDate = data["expiration_date"] as! String
            var nameOnCard = data["name_on_card"] as! String
            
            if expirationDate != "No Card on Record" {
                cardNumber = try! EncryptionManager.decryptMessage(encryptedMessage: cardNumber)
                expirationDate = try! EncryptionManager.decryptMessage(encryptedMessage: expirationDate)
                nameOnCard = try! EncryptionManager.decryptMessage(encryptedMessage: nameOnCard)
                self.checkExpirationDate(expirationDate: expirationDate)
            }
            
            self.sectionsArray[3] = Section(sectionName: "Payment Info", sectionRow: [cardNumber, expirationDate, nameOnCard])
            print("Got payment info data")
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
            }
        } else if yearExp < year { // if the year is before 2022, it's expired
            self.cardNeedsUpdateAlert()
        }
    }
    
    func textFieldsIncompleteAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "Could not be added. One or more fields were left empty or incomplete. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidStateAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The state you entered is invalid or abbreviated. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidExpirationDateAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The expiration date you entered is invalid. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func expiredCardAlert() {
        let alertController = UIAlertController(title: "Card Expired/Expiring", message: "The card you entered is expired or is expiring very soon. Please enter a new card that has an expiration date that is at least two months after the current date.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func cardNeedsUpdateAlert() {
        let alertController = UIAlertController(title: "Card Expired/Expiring", message: "The card we have on record for your account is expired or is expiring very soon. Please enter a new card that has an expiration date that is at least two months after the current date.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func modifyAddressButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Modify Delivery Address", message: "The address you enter here will replace any current delivery address on file.", preferredStyle: .alert)
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Street Address" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "City" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "State - Full Name" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Zip Code" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { _ in
            if alertController.textFields![0].text == "" || alertController.textFields![1].text == "" || alertController.textFields![2].text == "" || alertController.textFields![3].text == "" {
                self.textFieldsIncompleteAlert()
            } else {
                self.validateStateTextField(textFields: alertController.textFields!)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func validateStateTextField(textFields: [UITextField]) {
        // Validate the State (check what they entered and make sure it's an actualy state)
        let states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]
        
        if states.contains(textFields[2].text!) {
            self.modifyAddress(textFieldsInAlert: textFields)
        } else {
            self.invalidStateAlert()
        }
    }
    
    func modifyAddress(textFieldsInAlert: [UITextField]) {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        self.database.collection("account").document("account_\(userID)").collection("delivery_address").document("default").setData([
            "street_address": textFieldsInAlert[0].text!,
            "city": textFieldsInAlert[1].text!,
            "state": textFieldsInAlert[2].text!,
            "zip_code": textFieldsInAlert[3].text!,
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
        self.refreshTableData()
    }
    
    @IBAction func modifyPaymentInfoButtonTapped(_ sender: Any) {
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
        self.refreshTableData()
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
                } else { // Card expiration month is at least two months after the current month
                    self.modifyPaymentInfo(textFieldsInAlert: textFieldsInAlert)
                }
            } else if yearExp > year { // if the year is past 2022, it's not expired and is good to go
                self.modifyPaymentInfo(textFieldsInAlert: textFieldsInAlert)
            } else if yearExp < year { // if the year is before 2022, it's expired
                self.expiredCardAlert()
            }
        } else {
            self.invalidExpirationDateAlert()
        }
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
    
    
    // TABLE METHODS
    
    
    // Set height for the cells (might need to adjust the height here based on the data)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(75)
    }
    
    // Set the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return(sectionsArray.count)
    }
    
    // Set the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionsArray[section].sectionRow == nil {
            return 0
        } else {
            return(1)
        }
    }
    
    // Set values in cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Sections 0 and 1 will keep the code below (indexPath.section = 0 or 1)
        // Sections 2 and 3 will have custom cells, so the code below will be different for those sections only (indexPath.section = 2 or 3). These cells will have a button on them that will allow users to update that information in a UIAlert with text fields.
        if indexPath.section == 2 {
            // Runs when dealing with delivery data
            let cell = tableView.dequeueReusableCell(withIdentifier: "deliveryDataCell", for: indexPath) as! deliveryAddressCell
            cell.streetAddress.text = sectionsArray[2].sectionRow[0]
            if sectionsArray[2].sectionRow[1] == "No Address on Record" {
                cell.cityState.text = sectionsArray[2].sectionRow[1]
            } else { cell.cityState.text = "\(sectionsArray[2].sectionRow[1]), \(sectionsArray[2].sectionRow[2])" }
            cell.zipCode.text = sectionsArray[2].sectionRow[3]
            return(cell)
        } else if indexPath.section == 3 {
            // Runs when dealing with payment info data
            let cell = tableView.dequeueReusableCell(withIdentifier: "paymentInfoDataCell", for: indexPath) as! paymentInfoCell
            let cardNumber = sectionsArray[3].sectionRow[0]
            let expirationDate = sectionsArray[3].sectionRow[1]
            let nameOnCard = sectionsArray[3].sectionRow[2]
            if sectionsArray[3].sectionRow[1] == "No Card on Record" {
                cell.cardNumber.text = String(cardNumber)
            } else { cell.cardNumber.text = "**** **** **** \(cardNumber.suffix(4))" }
            cell.expirationDate.text = expirationDate
            cell.nameOnCard.text = nameOnCard
            return(cell)
        }
        // Runs when dealing with name and email address
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        cell.textLabel!.text = sectionsArray[indexPath.section].sectionRow[indexPath.row]
        return(cell)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsArray[section].sectionName
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Validating is done when the user taps "Enter," not here. Look up the regex codes. *Don't forget to not allow any text fields to be blank when the user taps the Enter button
        if textField.placeholder == "Street Address" {
            // Do nothing
        } else if textField.placeholder == "City" {
            // Don't allow numbers
            return dontAllowNumbers(string: string)
        } else if textField.placeholder == "State - Full Name" { // DONE HERE, NEEDS SPECIAL VALIDATING
            // Don't allow numbers
            // Validation Extra: make sure they enter a valid state (you might actually need to go through every state)
            return dontAllowNumbers(string: string)
        } else if textField.placeholder == "Zip Code" {
            // Only allow numbers
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Card Number" {
            // Only allow numbers and limit it to the max amount of numbers that could be on a card. Also automatically put spaces between every 4 digits
            if textField.text!.count >= 19 && string != "" {
                return false
            } else if ((textField.text?.count == 4 || textField.text?.count == 9 || textField.text?.count == 14) && string != "") {
                textField.text! += " "
            }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Expiration Date" { // DONE HERE, NEEDS SPECIAL VALIDATING
            // Only allow numbers and add a slash
            // Validation Extra: Check if it's expired, and if so, alert the user/don't add it.
            if textField.text!.count >= 5 && string != "" { return false }
            else if (textField.text?.count == 2) && string != "" { textField.text! += "/" }
            else if (textField.text?.count == 0) && string != "1" && string != "0" && string != "" { textField.text! += "0" }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Security Code" {
            // Only allow numbers
            if textField.text!.count >= 4 && string != "" { return false }
            return onlyAllowNumbers(string: string)
        } else if textField.placeholder == "Name on Card" {
            // Don't allow numbers (add this to the sign up page later too)
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
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            print("Sign out was successful!")
            UserDefaults().removeObject(forKey: "userData")
            self.performSegue(withIdentifier: "SignOut", sender: self)
        } catch { }
    }
    
}

class deliveryAddressCell: UITableViewCell {
    @IBOutlet weak var streetAddress: UILabel!
    @IBOutlet weak var cityState: UILabel!
    @IBOutlet weak var zipCode: UILabel!
}

class paymentInfoCell: UITableViewCell {
    @IBOutlet weak var cardNumber: UILabel!
    @IBOutlet weak var expirationDate: UILabel!
    @IBOutlet weak var nameOnCard: UILabel!
}
