//
//  CookOrderDetails.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class CookOrderDetails: UIViewController {
    
    private let database = Firestore.firestore()
    
    static var orderData = [String: Any]()
    @IBOutlet weak var orderDetailsTextArea: UITextView!
    @IBOutlet weak var startCookingButton: RoundedButton!
    @IBOutlet weak var finishedCookingButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getNewData()
    }
    
    func getNewData() {
        let orderID = CookOrderDetails.orderData["order_id"] as! String
        let docRef = self.database.collection("order").document("order_\(orderID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            CookOrderDetails.orderData = data
            self.setupButtons(); self.getContentsOfOrder()
        }
    }
    
    @IBAction func startCookingButtonTapped(_ sender: Any) {
        self.doubleCheckStatus()
    }
    
    func doubleCheckStatus() {
        let docRef = self.database.collection("order").document("order_\(CookOrderDetails.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            self.startCookingButton.isEnabled = false; self.startCookingButton.alpha = 0.35
            self.finishedCookingButton.isEnabled = true; self.finishedCookingButton.alpha = 1.0
            let orderStatus = data["status"] as! String
            if orderStatus == "Preparing to Cook" {
                // Ran when the order is not yet cooking
                self.changeOrderStatus(newStatus: "Cooking")
            } else if orderStatus == "Cooking" {
                // Ran when the order is already being cooked by another cook
                self.alreadyCookingAlert()
            }
        }
    }
    
    func alreadyCookingAlert() {
        let alertController = UIAlertController(title: "Already Started", message: "This order has already been started by another cook.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func doneCookingAlert() {
        let alertController = UIAlertController(title: "Done Cooking", message: "Done cooking this order?", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No", style: .default) { _ in }
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            if CookOrderDetails.orderData["order_type"] as! String == "Delivery" {
                self.changeOrderStatus(newStatus: "Preparing to Deliver")
            } else if CookOrderDetails.orderData["order_type"] as! String == "Pickup" {
                self.changeOrderStatus(newStatus: "Ready for Pickup")
            }
            self.finishedCookingButton.isEnabled = false; self.finishedCookingButton.alpha = 0.35
        }
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func finishedCookingButtonTapped(_ sender: Any) {
        doneCookingAlert()
    }
    
    func changeOrderStatus(newStatus: String) {
        let orderID = CookOrderDetails.orderData["order_id"] as! String
        self.database.collection("order").document("order_\(orderID)").setData([
            "status": newStatus,
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func getContentsOfOrder() {
        let result = CookOrderDetails.orderData["foods_in_order"] as! [String]
        self.orderDetailsTextArea.text = "Order Details\n\n"
        for i in result { self.orderDetailsTextArea.text += "• \(i)\n" }
        if CookOrderDetails.orderData["gift_card_applied"] as! Double != 0 {
            let formattedGCValue = String(format: "%.2f", CookOrderDetails.orderData["gift_card_applied"]! as! Double)
            self.orderDetailsTextArea.text += "\nGift Card Applied: $\(formattedGCValue)"
        }
        self.orderDetailsTextArea.text += "\nOrder Total: $\(CookOrderDetails.orderData["order_total"]!)"
    }
    
    func setupButtons() {
        let orderStatus = CookOrderDetails.orderData["status"] as! String
        if orderStatus == "Preparing to Cook" {
            self.startCookingButton.isEnabled = true; self.startCookingButton.alpha = 1.0
            self.finishedCookingButton.isEnabled = false; self.finishedCookingButton.alpha = 0.35
        } else {
            // Ran when the order is already being cooked by another cook
            self.startCookingButton.isEnabled = false; self.startCookingButton.alpha = 0.35
            self.finishedCookingButton.isEnabled = true; self.finishedCookingButton.alpha = 1.0
        }
    }
    
}
