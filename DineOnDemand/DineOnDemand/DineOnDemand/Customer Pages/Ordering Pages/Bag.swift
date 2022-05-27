//
//  OrderPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

//  Created by Louie Patrizi Jr. on 3/24/22

class Bag: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var table: UITableView!
    
    @IBOutlet weak var giftCardLabel: UILabel!
    @IBOutlet weak var giftCardValueLabel: UILabel!
    @IBOutlet weak var subtotalPriceLabel: UILabel!
    @IBOutlet weak var deliveryFeeLabel: UILabel!
    @IBOutlet weak var taxPriceLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var pickupButton: UIButton!
    @IBOutlet weak var deliveryButton: UIButton!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var emptyBagLabel: UILabel!
    @IBOutlet weak var applyGiftCardButton: UIButton!
    
    var deliveryFee: Int = 0
    var taxPrice: Double = 0.0 //not sure if we wanted to use a tax algorithm to calculate the tax
    var totalPrice: Double = 0
    var subtotalPrice: Int = 0
    static var giftCardValue: Double = 0 // The amount of the gift card balance we apply to the order
    static var remainingGiftCardBalance: Double = 0 // We use this to update the user's gift card balance when placing an order
    
    static var orderIdentity = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getLast4CardDigits(); setupGiftCardStuff()
        if CategoryFoods.bagItems.count != 0 { setDeliveryCharge(); calculateSubtotalPrice(); calculateTotalPrice() }
        else { table.isHidden = true }
    }
    
    func setupGiftCardStuff() {
        if CategoryFoods.bagItems.count != 0 { applyGiftCardButton.isEnabled = true }
        if Bag.giftCardValue == 0 { // Ran when the user doesnt have a gift card balance
            applyGiftCardButton.setTitle("Apply Gift Card", for: .normal)
            applyGiftCardButton.tintColor = .systemBlue
        } else if Bag.giftCardValue != 0 { // Ran when the user has a gift card balance
            applyGiftCardButton.setTitle("Remove Gift Card", for: .normal)
            applyGiftCardButton.tintColor = .systemRed
            giftCardLabel.isHidden = false; giftCardValueLabel.isHidden = false // Make Gift Card labels visible
            giftCardLabel.textColor = .systemBlue; giftCardValueLabel.textColor = .systemBlue
            let formattedGCValue = String(format: "%.2f", Bag.giftCardValue)
            giftCardValueLabel.text = "- $" + formattedGCValue
        }
    }
    
    @IBAction func payButtonTapped(_ sender: Any) {
        if self.payButton.titleLabel!.text == "Add Payment Method" {
            self.addPaymentMethodAlert()
        } else if self.payButton.titleLabel!.text == "Update Card" {
            self.addPaymentMethodAlert()
        } else {
            self.checkDeliveryAddressOnFile()
        }
    }
    
    func checkDeliveryAddressOnFile() {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"] as! String
        let docRef = database.collection("account").document("account_\(accountID)").collection("delivery_address").document("default")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let city = data["city"] as! String
            if city != "No Address on Record" || self.pickupButton.alpha == 1.00 {
                self.getNextAvailableOrderID() // adds the order to the database if an address is on file or its a pickup order.
            } else if city == "No Address on Record" {
                self.addAddressAlert() // asks the user to add a delivery address to their account if none was on file.
            }
        }
    }
    
    func addAddressAlert() {
        let alertController = UIAlertController(title: "Add Delivery Address", message: "No delivery address on file. Please enter your delivery address here.", preferredStyle: .alert)
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Street Address" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "City" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "State - Full Name" }
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Zip Code" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Save and Place Order", style: .default) { _ in
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
            self.getNextAvailableOrderID()
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
    }
    
    func invalidStateAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "The state you entered is invalid or abbreviated. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func getNextAvailableOrderID() {
        database.collection("order").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var orderID = 0
                for document in querySnapshot!.documents {
                    let tempOrderID = Int(document.data()["order_id"] as! String)!
                    if orderID < tempOrderID { orderID = tempOrderID }
                }
                self.createCorrectTypeOfOrder(orderID: orderID + 1)
                self.updateDBGiftCardBalance(remainingBalance: Bag.remainingGiftCardBalance) // Updates gift card balance in database
                Bag.giftCardValue = 0; Bag.remainingGiftCardBalance = 0
            }
        }
    }
    
    func createCorrectTypeOfOrder(orderID: Int) {
        if self.pickupButton.alpha == 1.0 { // Pickup was chosen
            print("Pickup Order")
            Bag.orderIdentity = orderID
            print("Order ID: \(Bag.orderIdentity)")
            self.addPickupOrderToDatabase(orderID: orderID)
            self.grabOrderInfo()
        } else if self.deliveryButton.alpha == 1.0 { // Delivery was chosen
            print("Delivery Order")
            Bag.orderIdentity = orderID
            print("Order ID: \(Bag.orderIdentity)")
            self.getCustomerDeliveryAddress(orderID: orderID)
        }
    }
    
    func getCustomerDeliveryAddress(orderID: Int) {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"] as! String
        let docRef = database.collection("account").document("account_\(accountID)").collection("delivery_address").document("default")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let streetAddress = data["street_address"] as! String; let city = data["city"] as! String
            let state = data["state"]; let zipCode = data["zip_code"] as! String
            let deliveryAddress = [streetAddress, city, state, zipCode] as! [String]
            self.addDeliveryOrderToDatabase(orderID: orderID, deliveryAddress: deliveryAddress)
        }
    }
    
    @IBAction func changeCardButtonTapped(_ sender: Any) {
        addPaymentMethodAlert()
        getLast4CardDigits()
    }
    
    @IBAction func applyGiftCardButtonTapped(_ sender: Any) {
        if applyGiftCardButton.titleLabel!.text == "Apply Gift Card" {
            getGiftCardBalance()
        } else if applyGiftCardButton.titleLabel!.text == "Remove Gift Card" {
            giftCardLabel.isHidden = true; giftCardValueLabel.isHidden = true
            applyGiftCardButton.setTitle("Apply Gift Card", for: .normal)
            applyGiftCardButton.tintColor = .systemBlue
            Bag.giftCardValue = 0; Bag.remainingGiftCardBalance = 0
            calculateTotalPrice()
        }
    }
    
    func getGiftCardBalance() {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"] as! String
        let docRef = database.collection("account").document("account_\(accountID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            self.showApplyGiftCardAlert(giftCardBalance: data["gift_card_balance"] as! Double)
        }
    }
    
    func showApplyGiftCardAlert(giftCardBalance: Double) {
        let formattedGCBalance = String(format: "%.2f", giftCardBalance)
        let alertController = UIAlertController(title: "Apply Gift Card Balance", message: "Your current gift card balance is $\(formattedGCBalance). Please enter an amount that is equal to or less than your balance.", preferredStyle: .alert)
        alertController.addTextField { textField in textField.delegate = self; textField.placeholder = "Balance to Apply"; textField.text = "$" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Apply", style: .default) { _ in
            let enteredValue = Double("\(alertController.textFields![0].text!)".dropFirst())! // ** Don't forget to drop the cash sign!!
            if alertController.textFields![0].text == "" || alertController.textFields![0].text == "0" { // Change to "$0" later
                self.emptyBalanceAlert()
            } else if giftCardBalance < enteredValue { // Ran when the user enters a value that passes their balance in the database
                self.invalidGCAmountAlert()
            } else if Double(enteredValue) > self.totalPrice {
                print("Entered Value:", enteredValue); print("Order Total:", self.totalPrice)
                self.invalidGCAmount2Alert()
            } else {
                let remainingBalance = giftCardBalance - enteredValue // Calculates remaining gift card balance
                Bag.giftCardValue = enteredValue; Bag.remainingGiftCardBalance = remainingBalance
                self.deductGCFromOrder(enteredValue: enteredValue) // Deduct locally
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func deductGCFromOrder(enteredValue: Double) {
        giftCardLabel.isHidden = false; giftCardValueLabel.isHidden = false // Make Gift Card labels visible
        giftCardLabel.textColor = .systemBlue; giftCardValueLabel.textColor = .systemBlue
        let formattedGCValue = String(format: "%.2f", enteredValue)
        giftCardValueLabel.text = "- $" + formattedGCValue
        applyGiftCardButton.setTitle("Remove Gift Card", for: .normal)
        applyGiftCardButton.tintColor = .systemRed
        calculateTotalPrice()
    }
    
    func updateDBGiftCardBalance(remainingBalance: Double) {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"]
        self.database.collection("account").document("account_\(accountID!)").setData([
            "gift_card_balance": remainingBalance,
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { }
        }
    }
    
    func addPickupOrderToDatabase(orderID: Int) {
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        self.database.collection("order").document("order_\(orderID)").setData([
            "account_id": userData["account_id"] as! String,
            "day_of_order": getDate(),
            "time_of_order": getTime(),
            "foods_in_order": getFoodsArray(),
            "order_type": "Pickup",
            "order_id": String(orderID),
            "order_total": String((totalPriceLabel.text?.dropFirst())!),
            "ordered_by": userData["full_name"] as! String,
            "restaurant_code": RestaurantDetailsPage.restaurantCode,
            "restaurant_name": RestaurantDetailsPage.restaurantName,
            "status": "Preparing to Cook",
            "gift_card_applied": Bag.giftCardValue
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { self.orderPlacedAlert() }
        }
    }
    
    func addDeliveryOrderToDatabase(orderID: Int, deliveryAddress: [String]) {
        self.grabOrderInfo()
        let userData: Dictionary = UserDefaults().dictionary(forKey: "userData")!
        self.database.collection("order").document("order_\(orderID)").setData([
            "account_id": userData["account_id"] as! String,
            "day_of_order": getDate(),
            "time_of_order": getTime(),
            "foods_in_order": getFoodsArray(),
            "delivery_address": deliveryAddress,
            "order_type": "Delivery",
            "order_id": String(orderID),
            "order_total": String((totalPriceLabel.text?.dropFirst())!),
            "ordered_by": userData["full_name"] as! String,
            "restaurant_code": RestaurantDetailsPage.restaurantCode,
            "restaurant_name": RestaurantDetailsPage.restaurantName,
            "status": "Preparing to Cook",
            "gift_card_applied": Bag.giftCardValue
        ]) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { self.orderPlacedAlert() }
        }
    }
    
    var dateOfOrder = " "
    func grabOrderInfo(){
        let docRef = database.collection("order").document("order_\(Bag.orderIdentity)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let dayOfOrder = data["day_of_order"] as! String
            let orderPrice = data["order_total"] as! String
            self.dateOfOrder = dayOfOrder
            var totalOrderPrice = 0.0
            totalOrderPrice = Double(orderPrice)!
            self.updateBudgetDataInDatabaseHelpMethod(dateOfOrder: self.dateOfOrder, orderPrice: totalOrderPrice)
        }
    }
    
    func updateBudgetDataInDatabaseHelpMethod(dateOfOrder: String, orderPrice: Double){
        //splits the order data into 3 elements to be analyzed
        let splittedDate = dateOfOrder.split(separator: "/")
        let year = splittedDate[2]
        let month = splittedDate[0]
        let day = splittedDate[1]
        var inputYear = " "
        if(Int(year) == 21){inputYear = "2021"}
        else if (Int(year) == 22){inputYear = "2022"}
        else if (Int(year) == 23){inputYear = "2023"}
        var inputMonth = " "
        let splitMonth = Array(month)
        var tempMonthNumber = 0
        //for the months that have a 0 in front -> 1-9
        if(month.contains("0")){
            for i in 1..<10{
                //grabs the month number without the 0 to be put in when searching which document to update in database. Since each document is a month of the year
                if(splitMonth[1].wholeNumberValue == i){ inputMonth = "0\(i)_\(inputYear)"
                    tempMonthNumber = splitMonth[1].wholeNumberValue!
                }
            }
        }else{
            if(Int(month) == 10){ inputMonth = "10_\(inputYear)"}
            else if(Int(month) == 11){ inputMonth = "11_\(inputYear)"}
            else if(Int(month) == 12){ inputMonth = "12_\(inputYear)"}
        }
        //grabs week of the month based on day
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(calendar: calendar, era: 1, year: Int(inputYear), month: tempMonthNumber , day: Int(day)))
        print("Here is the week of the month your order falls in:")
        print(day, calendar.component(.weekOfMonth, from: date!))
        let weekOfTheMonth = calendar.component(.weekOfMonth, from: date!)
        //database interaction
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").document("\(inputYear)").collection("monthlyData").document("\(inputMonth)")
        docRef.getDocument { snapshot, error in
            guard let document = snapshot?.data(), error == nil else {
                return
            }
            //dictionary for each field for each week in document
            let weekBudgetDictionary = document["week_\(weekOfTheMonth)"] as! [String: Any]
            //variable that shows the day range of the week the order falls under
            let weekBeingUpdated = weekBudgetDictionary["dayRange"] as! String
            //variable to hold the new price to be added to database after placing order
            var updatedWeekPriceAmount = 0.0
            //grabbing the current amount stored in database
            let amountAlreadySpent = weekBudgetDictionary["amountSpent"] ?? "No price found!"
            updatedWeekPriceAmount = amountAlreadySpent as! Double + orderPrice
            //updates the amountSpent field in the database to the correct amount after an order is placed
            docRef.updateData(["week_\(weekOfTheMonth).amountSpent" : updatedWeekPriceAmount])
            //info to help see what is being updated in database
            print("Updated Week Price: \(updatedWeekPriceAmount)")
            print("Week Being Updated: \(weekBeingUpdated)")
        }
    }
    
    func getDate() -> String {
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MM/dd/yy"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    func getTime() -> String {
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: Date())
        return timeString
    }
    
    func getFoodsArray() -> [String] {
        var foodsArray = [String]()
        for i in 0...CategoryFoods.bagItems.count - 1 {
            let itemName = CategoryFoods.bagItems[i].orderedItem
            let itemPrice = CategoryFoods.bagItems[i].price
            let quantity = CategoryFoods.bagItems[i].quantity
            foodsArray.append("\(itemName) $\(itemPrice) | \(quantity)")
        }
        return foodsArray
    }
    
    @IBAction func pickupButtonTapped(_ sender: Any) {
        if CategoryFoods.bagItems.count != 0 {
            pickupButton.alpha = 1.0; deliveryButton.alpha = 0.5; payButton.isEnabled = true
            setDeliveryCharge(); calculateTotalPrice()
        }
    }
    
    @IBAction func deliveryButtonTapped(_ sender: Any) {
        if CategoryFoods.bagItems.count != 0 {
            pickupButton.alpha = 0.5; deliveryButton.alpha = 1.0; payButton.isEnabled = true
            setDeliveryCharge(); calculateTotalPrice()
        }
    }
    
    func setDeliveryCharge() {
        if deliveryButton.alpha == 1.0 {
            deliveryFee = 5; deliveryFeeLabel.text = "$\(deliveryFee).00"
        } else if deliveryButton.alpha == 0.5 {
            deliveryFee = 0; deliveryFeeLabel.text = "$\(deliveryFee).00"
        }
    }
    
    //calculates the subtotal for the bill at the end of order. (the sum of all items selected for order without tax and other fees)
    //taken from orderedItems array. Multiplys with quantity to ensure the correct cost is there
    func calculateSubtotalPrice() {
        subtotalPrice = 0
        let orderCount = CategoryFoods.bagItems.count
        for x in 1...orderCount { subtotalPrice = subtotalPrice + (CategoryFoods.bagItems[x-1].price) }
        subtotalPriceLabel.text = "$\(subtotalPrice).00"
    }
    
    func calculateTotalPrice() {
        var totalPriceWithoutTax = 0
        totalPriceWithoutTax = subtotalPrice + deliveryFee
        taxPrice = Double(totalPriceWithoutTax) * 0.0863
        //rounds the tax price to the nearest hundredths place
        let roundedTaxPrice = round(taxPrice * 100) / 100.0
        let formattedTax = String(format: "%.2f", roundedTaxPrice)
        taxPriceLabel.text = "$\(formattedTax)"
        let totalPriceWithTax = (Double(subtotalPrice) + roundedTaxPrice + Double(deliveryFee)) - Double(Bag.giftCardValue)
        totalPrice = totalPriceWithTax
        let formattedTotal = String(format: "%.2f", totalPriceWithTax)
        totalPriceLabel.text = "$\(formattedTotal)"
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
                self.payButton.setTitle("Pay now with *\(cardNumber.suffix(4))", for: .normal)
            } else {
                self.payButton.setTitle("Add Payment Method", for: .normal)
            }
            // Check card expiration date
            var expirationDate = data["expiration_date"] as! String
            if expirationDate != "No Card on Record" {
                expirationDate = try! EncryptionManager.decryptMessage(encryptedMessage: expirationDate)
                self.checkExpirationDate(expirationDate: expirationDate)
            }
        }
    }
    
    func addPaymentMethodAlert() {
        let alertController = UIAlertController(title: "Add Payment Info", message: "The payment info you enter here will replace any current payment info on file.", preferredStyle: .alert)
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
                self.payButton.setTitle("Update Card", for: .normal)
                //self.payButton.isEnabled = true
            }
        } else if yearExp < year { // if the year is before 2022, it's expired
            self.cardNeedsUpdateAlert()
            self.payButton.setTitle("Update Card", for: .normal)
            //self.payButton.isEnabled = true
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
                    if !((payButton.titleLabel!.text)?.contains("*"))! { self.payButton.isEnabled = true }
                }
            } else if yearExp > year { // if the year is past 2022, it's not expired and is good to go
                self.modifyPaymentInfo(textFieldsInAlert: textFieldsInAlert)
                if !((payButton.titleLabel!.text)?.contains("*"))! { self.payButton.isEnabled = true }
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
    
    func orderPlacedAlert() {
        let alertController = UIAlertController(title: "Order Placed", message: "Your order has been successfully placed! You will now be redirected to the Welcome page.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.performSegue(withIdentifier: "ReturnToWelcomePage", sender: self)
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func textFieldsIncompleteAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "Could not be added. One or more fields were left empty or incomplete. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in}
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func emptyBalanceAlert() {
        let alertController = UIAlertController(title: "Try Again", message: "Please enter something in the field before attempting to apply a gift card balance.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.getGiftCardBalance()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidGCAmountAlert() {
        let alertController = UIAlertController(title: "Invalid", message: "The value you entered is larger than your current gift card balance. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.getGiftCardBalance()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidGCAmount2Alert() {
        let alertController = UIAlertController(title: "Invalid", message: "The value you entered is larger than your order total. Please try again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.getGiftCardBalance()
        }
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
    
    func validate(userEntry: String, regEx: String) -> Bool {
        let regEx = regEx
        let trimmedString = userEntry.trimmingCharacters(in: .whitespaces)
        let validateEntry = NSPredicate(format:"SELF MATCHES %@", regEx)
        let isValid = validateEntry.evaluate(with: trimmedString)
        return isValid
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
        
        if textField.placeholder == "Balance to Apply" {
            if ((textField.text)!.contains(".") && string != "") && (textField.text?.dropLast().dropLast().last == ".") {
                return false
            }
            if (textField.text == "$" && string == "") { // The only text in the textfield is '$' and backspace was entered
                return false
            } else if (textField.text != "$" && string == "") { // There is more than just "$" in the text field and backspace was entered
                return true
            } else if (string == "." && textField.text?.last != "$") && !(textField.text)!.contains(".") {
                return true
            } else if string != "0" && string != "1" && string != "2" && string != "3" && string != "4" && string != "5" && string != "6" && string != "7" && string != "8" && string != "9" { // A non-number character was entered
                return false
            }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CategoryFoods.bagItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(97)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BagCell", for: indexPath) as! orderPageItemCell
        cell.orderedItemLabel.text = "\(CategoryFoods.bagItems[indexPath.row].orderedItem)"
        cell.priceLabel.text = "$\(CategoryFoods.bagItems[indexPath.row].price)"
        cell.quantityValueLabel.text = "\(CategoryFoods.bagItems[indexPath.row].quantity)"
        return(cell)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        print("Deleted item at index: \(indexPath.row)")
        CategoryFoods.bagItems.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        if totalPrice < Double(Bag.giftCardValue) {
            applyGiftCardButton.setTitle("Apply Gift Card", for: .normal)
            applyGiftCardButton.tintColor = .systemBlue
            giftCardLabel.isHidden = true; giftCardValueLabel.isHidden = true
            Bag.giftCardValue = 0; Bag.remainingGiftCardBalance = 0
            calculateTotalPrice()
        }
        if CategoryFoods.bagItems.count != 0 { setDeliveryCharge(); calculateSubtotalPrice(); calculateTotalPrice() }
        else if CategoryFoods.bagItems.count == 0 {
            deliveryButton.alpha = 0.5; pickupButton.alpha = 0.5; payButton.isEnabled = false; table.isHidden = true
            applyGiftCardButton.isEnabled = false
            totalPrice = 0
            subtotalPriceLabel.text = "$0.00"; deliveryFeeLabel.text = "$0.00"; taxPriceLabel.text = "$0.00"
            totalPriceLabel.text = "$0.00"
            applyGiftCardButton.setTitle("Apply Gift Card", for: .normal)
            applyGiftCardButton.tintColor = .systemBlue
            giftCardLabel.isHidden = true; giftCardValueLabel.isHidden = true
            Bag.giftCardValue = 0; Bag.remainingGiftCardBalance = 0
        }
    }
    
}

class orderPageItemCell: UITableViewCell {
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var orderedItemLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
}
