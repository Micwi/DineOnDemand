//
//  ManagerOrderDetails.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class ManagerOrderDetails: UIViewController {
    
    private let database = Firestore.firestore()
    
    static var orderData = [String: Any]()
    @IBOutlet weak var orderStatusLabel: UILabel!
    @IBOutlet weak var orderContentsLabel: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        orderStatusLabel.text = ManagerOrderDetails.orderData["status"] as? String
        getContentsOfOrder()
    }
    
    func getContentsOfOrder() {
        let docRef = self.database.collection("order").document("order_\(ManagerOrderDetails.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let result = data["foods_in_order"] as! [String]
            self.orderContentsLabel.text = "Order Details\n\n"
            for i in result { self.orderContentsLabel.text += "• \(i)\n" }
            if ManagerOrderDetails.orderData["gift_card_applied"] as! Double != 0 {
                let formattedGCValue = String(format: "%.2f", ManagerOrderDetails.orderData["gift_card_applied"]! as! Double)
                self.orderContentsLabel.text += "\nGift Card Applied: $\(formattedGCValue)"
            }
            self.orderContentsLabel.text += "\nOrder Total: $\(ManagerOrderDetails.orderData["order_total"]!)"
        }
    }
    
}
