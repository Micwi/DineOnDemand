//
//  WelcomePage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/5/22.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth

class WelcomePage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var budgetLabel: UILabel!
    @IBOutlet weak var giftCardBalanceLabel: UILabel!
    @IBOutlet weak var disableBudgetButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        loadGCAndBudgetData()
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
    
    func loadGCAndBudgetData() {
        let accountID: String = UserDefaults().dictionary(forKey: "userData")!["account_id"] as! String
        let docRef = self.database.collection("account").document("account_\(accountID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let lastResetDateString = data["last_reset_date"] ?? self.getSundaysDate(from: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let lastResetDate = dateFormatter.date(from: lastResetDateString as! String)
            let lastResetDatePlus7Days = Calendar.current.date(byAdding: .day, value: 7, to: lastResetDate!)
            
            var amountSpent = data["amount_spent"] ?? 0
            if Date() >= lastResetDatePlus7Days! { self.resetAmountSpent(); amountSpent = 0 }
            
            let budget = data["budget"] ?? 0
            if budget as! Int == 0 { self.budgetLabel.text = "Budget Not Set" }
            else { self.budgetLabel.text = "$\(amountSpent)/$\(data["budget"] ?? 0)"; self.disableBudgetButton.isHidden = false }
            
            let giftCardBalance = data["gift_card_balance"] as! Double
            let formattedGCBalance = String(format: "%.2f", giftCardBalance)
            if giftCardBalance != 0 {
                self.giftCardBalanceLabel.isHidden = false
                self.giftCardBalanceLabel.text = "Gift Card Balance: $\(formattedGCBalance)"
            }
        }
    }
    
    func resetAmountSpent() {
        let userData = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"]!
        
        self.database.collection("account").document("account_\(accountID)").setData([
            "amount_spent": 0,
            "last_reset_date": getSundaysDate(from: Date()),
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    @IBAction func setBudgetButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Set a Weekly Budget", message: "Set a weekly budget that resets every Sunday at midnight.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.delegate = self
            textField.text = "$"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { _ in
            let enteredBudget = Int((alertController.textFields![0].text?.dropFirst())!) ?? 0
            self.setBudget(budget: enteredBudget)
            self.loadGCAndBudgetData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func disableBudgetButtonTapped(_ sender: Any) {
        disableBudgetButton.isHidden = true
        self.budgetLabel.text = "Budget Not Set"
        // Delete those three fields in the database for this account here!
        let userData = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"]!
        
        self.database.collection("account").document("account_\(accountID)").setData([
            "budget": FieldValue.delete(),
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func setBudget(budget: Int) {
        let userData = UserDefaults().dictionary(forKey: "userData")!
        let accountID = userData["account_id"]!
        
        self.database.collection("account").document("account_\(accountID)").setData([
            "budget": budget,
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text == "$" && string == "") { // The only text in the textfield is '$' and backspace was entered
            return false
        } else if (textField.text != "$" && string == "") { // There is more than just "$" in the text field and backspace was entered
            return true
        } else if string != "0" && string != "1" && string != "2" && string != "3" && string != "4" && string != "5" && string != "6" && string != "7" && string != "8" && string != "9" { // A non-number character was entered
            return false
        }
        return true
    }
    
}

extension Date {
    var components:DateComponents {
        let cal = NSCalendar.current
        return cal.dateComponents(Set([.year, .month, .day, .hour,.minute, .second, .weekday, .weekOfYear, .yearForWeekOfYear]),from: self)
    }
}
